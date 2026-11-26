import argparse
import asyncio
import os
from collections.abc import AsyncIterator, Callable
from concurrent.futures import ThreadPoolExecutor
from contextlib import asynccontextmanager
from dataclasses import dataclass
from functools import partial
from pathlib import Path
from secrets import compare_digest
from typing import Annotated, Literal

import uvicorn
from fastapi import Depends, FastAPI, Form, HTTPException, UploadFile
from fastapi.responses import FileResponse, Response
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from prometheus_client import (
    CONTENT_TYPE_LATEST,
    CollectorRegistry,
    Gauge,
    generate_latest,
)
from pydantic import Json

from .audio import MAX_UPLOAD_BYTES, InvalidAudio
from .engine import CHECKPOINTS, CheckpointUnavailable, Engine, GPUOutOfMemory
from .schema import (
    MEDIA_TYPES,
    Artifact,
    ArtifactId,
    Edit,
    Generation,
    Inpaint,
    Manifest,
    ModelName,
)


@dataclass(frozen=True)
class Settings:
    artifact_dir: Path
    token: str | None = None
    eager_model: ModelName | None = None
    max_batch: int = 4
    max_resident: int = 1
    queue_slots: int = 4


def create_app(settings: Settings) -> FastAPI:
    registry = CollectorRegistry()
    in_flight = Gauge(
        "stable_audio_jobs", "Active and queued GPU jobs", registry=registry
    )
    engine = Engine(settings.artifact_dir, settings.max_resident, registry)
    executor = ThreadPoolExecutor(max_workers=1, thread_name_prefix="stable-audio-gpu")
    pending = 0

    def finished(task: asyncio.Future[object]) -> None:
        nonlocal pending
        pending -= 1
        in_flight.set(pending)
        if not task.cancelled():
            task.exception()

    async def submit[T](operation: Callable[[], T]) -> T:
        nonlocal pending
        if pending >= settings.queue_slots:
            raise HTTPException(429, "GPU queue is full", headers={"Retry-After": "1"})
        job = executor.submit(operation)
        pending += 1
        in_flight.set(pending)
        completion = asyncio.wrap_future(job)
        completion.add_done_callback(finished)
        try:
            # A disconnected request may cancel a waiting job. An active job still
            # owns its queue slot and GPU until the worker finishes it.
            return await asyncio.shield(completion)
        except asyncio.CancelledError:
            job.cancel()
            raise
        except (GPUOutOfMemory, CheckpointUnavailable) as exc:
            raise HTTPException(503, str(exc)) from exc
        except InvalidAudio as exc:
            raise HTTPException(422, str(exc)) from exc

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        try:
            await submit(engine.start)
            if settings.eager_model is not None:
                await submit(partial(engine.load, settings.eager_model))
            yield
        finally:
            await asyncio.to_thread(executor.shutdown, cancel_futures=True)

    bearer = HTTPBearer(auto_error=False)

    async def authenticate(
        credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer)],
    ) -> None:
        if settings.token is None:
            return
        if credentials is None or not compare_digest(
            credentials.credentials.encode(), settings.token.encode()
        ):
            raise HTTPException(
                401, "Bearer token required", headers={"WWW-Authenticate": "Bearer"}
            )

    app = FastAPI(
        title="Stable Audio 3",
        version="0.1.0",
        dependencies=[Depends(authenticate)],
        lifespan=lifespan,
    )

    @app.get("/health")
    async def health() -> dict[str, str]:
        return {"status": "ok"}

    @app.get("/ready")
    async def ready() -> dict[str, object]:
        return {
            "status": "ready",
            "device": "cuda",
            "loaded_models": [name for name in CHECKPOINTS if name in engine.models],
        }

    @app.get("/metrics")
    async def metrics() -> Response:
        return Response(generate_latest(registry), media_type=CONTENT_TYPE_LATEST)

    @app.get("/v1/models")
    async def models() -> dict[str, object]:
        return {
            "models": [
                {
                    "id": name,
                    "checkpoint_revision": revision,
                    "loaded": name in engine.models,
                }
                for name, revision in CHECKPOINTS.items()
            ],
            "max_batch": settings.max_batch,
            "max_resident": settings.max_resident,
        }

    @app.post("/v1/models/{model}/load")
    async def load(model: ModelName) -> dict[str, object]:
        seconds = await submit(partial(engine.load, model))
        return {"id": model, "loaded": True, "load_seconds": seconds}

    @app.post("/v1/models/{model}/unload")
    async def unload(model: ModelName) -> dict[str, object]:
        await submit(partial(engine.unload, model))
        return {"id": model, "loaded": False}

    def download(artifact: Artifact, *, original: bool = False) -> FileResponse:
        batch, index = artifact.id.split(".")
        audio_format = "wav" if original else artifact.format
        filename = f"{index}.original.wav" if original else f"{index}.{audio_format}"
        return FileResponse(
            settings.artifact_dir / batch / filename,
            media_type=MEDIA_TYPES[audio_format],
            filename=f"{artifact.id}{'.original' if original else ''}.{audio_format}",
            headers={"X-Artifact-Id": artifact.id, "X-Seed": str(artifact.seed)},
        )

    async def generate(
        options: Generation, reference: UploadFile | None = None
    ) -> Manifest | FileResponse:
        if options.variations > settings.max_batch:
            raise HTTPException(
                422, f"variations exceeds max batch size of {settings.max_batch}"
            )
        data = None
        if reference is not None:
            data = await reference.read(MAX_UPLOAD_BYTES + 1)
            if len(data) > MAX_UPLOAD_BYTES:
                raise HTTPException(413, "reference audio exceeds 32 MiB")
        manifest = await submit(partial(engine.generate, options, data))
        return (
            download(manifest.artifacts[0]) if options.response == "audio" else manifest
        )

    audio_responses = {
        200: {"content": {media_type: {} for media_type in MEDIA_TYPES.values()}}
    }

    @app.post(
        "/v1/audio/generations", response_model=Manifest, responses=audio_responses
    )
    async def generations(options: Generation) -> Manifest | FileResponse:
        return await generate(options)

    @app.post("/v1/audio/edits", response_model=Manifest, responses=audio_responses)
    async def edits(
        options: Annotated[Json[Edit], Form()], reference: UploadFile
    ) -> Manifest | FileResponse:
        return await generate(options, reference)

    @app.post("/v1/audio/inpaint", response_model=Manifest, responses=audio_responses)
    async def inpaint(
        options: Annotated[Json[Inpaint], Form()], reference: UploadFile
    ) -> Manifest | FileResponse:
        return await generate(options, reference)

    @app.get(
        "/v1/audio/artifacts/{id}", response_model=Artifact, responses=audio_responses
    )
    def artifact(
        id: ArtifactId, file: Literal["audio", "original", "metadata"] = "audio"
    ) -> Artifact | FileResponse:
        batch, index = id.split(".")
        try:
            manifest = Manifest.model_validate_json(
                (settings.artifact_dir / batch / "manifest.json").read_bytes()
            )
            item = manifest.artifacts[int(index)]
        except (FileNotFoundError, IndexError) as exc:
            raise HTTPException(404, "Artifact not found") from exc
        if item.id != id:
            raise HTTPException(404, "Artifact not found")
        return (
            item if file == "metadata" else download(item, original=file == "original")
        )

    return app


def main() -> None:
    state_home = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state")
    parser = argparse.ArgumentParser(
        description="Serve Stable Audio 3 on a single CUDA GPU"
    )
    parser.add_argument(
        "--host", default=os.environ.get("STABLE_AUDIO_HOST", "127.0.0.1")
    )
    parser.add_argument(
        "--port", type=int, default=os.environ.get("STABLE_AUDIO_PORT", "8766")
    )
    parser.add_argument(
        "--artifact-dir",
        type=Path,
        default=os.environ.get(
            "STABLE_AUDIO_ARTIFACT_DIR", state_home / "stable-audio-3"
        ),
    )
    parser.add_argument("--eager-model", choices=CHECKPOINTS)
    parser.add_argument(
        "--max-batch", type=int, choices=range(1, 17), default=4, metavar="1-16"
    )
    parser.add_argument(
        "--max-resident", type=int, choices=range(1, 4), default=1, metavar="1-3"
    )
    parser.add_argument(
        "--queue-slots", type=int, default=4, help="Total active and waiting GPU jobs"
    )
    args = parser.parse_args()
    if args.queue_slots < 1:
        parser.error("--queue-slots must be positive")
    settings = Settings(
        artifact_dir=args.artifact_dir,
        token=os.environ.get("STABLE_AUDIO_TOKEN") or None,
        eager_model=args.eager_model,
        max_batch=args.max_batch,
        max_resident=args.max_resident,
        queue_slots=args.queue_slots,
    )
    uvicorn.run(create_app(settings), host=args.host, port=args.port, workers=1)
