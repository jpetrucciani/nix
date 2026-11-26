import argparse
import json
import os
from io import BytesIO
from pathlib import Path
from time import perf_counter
from typing import Any
from urllib.error import HTTPError
from urllib.request import Request, urlopen

import soundfile as sf

from .schema import Artifact, Generation, Manifest

GOLF_PROMPTS = {
    "ball-on-ball": "Two hard golf balls click as they collide, isolated close-mic sound effect",
    "ball-on-wood": "A golf ball strikes a wooden board with a sharp, hollow knock, isolated sound effect",
    "ball-on-concrete": "A golf ball strikes concrete, a hard bright impact and short bounce, isolated sound effect",
    "ball-on-metal": "A golf ball strikes a metal plate with a short metallic ring, isolated sound effect",
    "ball-in-cup": "A golf ball drops into a putting cup and rattles against the bottom, isolated sound effect",
}


class Client:
    def __init__(self, url: str, timeout: float) -> None:
        self.url = url.rstrip("/")
        self.timeout = timeout
        token = os.environ.get("STABLE_AUDIO_TOKEN")
        self.headers = {"Authorization": f"Bearer {token}"} if token else {}

    def request(
        self, path: str, method: str = "GET", data: bytes | None = None
    ) -> bytes:
        headers = self.headers | (
            {"Content-Type": "application/json"} if data is not None else {}
        )
        with urlopen(
            Request(self.url + path, method=method, headers=headers, data=data),
            timeout=self.timeout,
        ) as response:
            return response.read()

    def generate(self, request: Generation) -> tuple[list[Artifact], float]:
        start = perf_counter()
        data = self.request(
            "/v1/audio/generations", "POST", request.model_dump_json().encode()
        )
        duration = perf_counter() - start
        artifacts = Manifest.model_validate_json(data).artifacts
        if len(artifacts) != request.variations:
            raise RuntimeError("incorrect number of returned artifacts")
        return artifacts, duration

    def wav(self, item: Artifact, seconds: float) -> bytes:
        data = self.request(item.download_url)
        info = sf.info(BytesIO(data))
        if info.samplerate != item.original_sample_rate or info.frames != int(
            seconds * info.samplerate
        ):
            raise RuntimeError(f"unexpected duration or sample rate for {item.id}")
        return data


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Benchmark the Stable Audio 3 service and save golf sound effects"
    )
    parser.add_argument("--url", default="http://127.0.0.1:8766")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument(
        "--timeout", type=float, default=240, help="Per-request timeout in seconds"
    )
    parser.add_argument("--audition-only", action="store_true")
    args = parser.parse_args()

    client = Client(args.url, args.timeout)
    max_batch = json.loads(client.request("/v1/models"))["max_batch"]
    args.output.mkdir(parents=True, exist_ok=True)

    if not args.audition_only:
        with (args.output / "results.jsonl").open("w", encoding="utf-8") as results:
            for model in ("small-sfx", "medium"):
                for seconds in (0.5, 1, 2, 5, 10):
                    for size in (1, 2, 4, 8, 16):
                        if size > max_batch:
                            continue
                        client.request(f"/v1/models/{model}/unload", "POST")
                        request = Generation(
                            model=model,
                            prompt=GOLF_PROMPTS["ball-on-ball"],
                            duration=seconds,
                            variations=size,
                            seed=42,
                        )
                        for phase in ("cold", "warm"):
                            row: dict[str, Any] = {
                                "model": model,
                                "duration": seconds,
                                "batch_size": size,
                                "phase": phase,
                            }
                            try:
                                artifacts, elapsed = client.generate(request)
                            except HTTPError as exc:
                                detail = json.loads(exc.read()).get("detail", "")
                                if exc.code != 503 or not detail.startswith(
                                    "CUDA ran out of memory"
                                ):
                                    raise RuntimeError(
                                        f"{model}: {detail or exc.reason}"
                                    ) from exc
                                row["error"] = detail
                            else:
                                for item in artifacts:
                                    client.wav(item, seconds)
                                item = artifacts[0]
                                row.update(
                                    wall_seconds=elapsed,
                                    audio_seconds_per_wall_second=seconds
                                    * size
                                    / elapsed,
                                    sample_rate=item.sample_rate,
                                    load_seconds=item.load_seconds,
                                    inference_seconds=item.inference_seconds,
                                    peak_vram_bytes=item.peak_vram_bytes,
                                    resident_vram_bytes=item.resident_vram_bytes,
                                    checkpoint_revision=item.checkpoint_revision,
                                )
                            print(json.dumps(row), file=results, flush=True)
                            if "error" in row:
                                break

    for name, prompt in GOLF_PROMPTS.items():
        seed = 42
        while seed < 46:
            size = min(max_batch, 46 - seed)
            request = Generation(prompt=prompt, duration=2, seed=seed, variations=size)
            artifacts, _ = client.generate(request)
            for item in artifacts:
                (
                    args.output / f"{name}-{seed - 41 + item.batch_index}.wav"
                ).write_bytes(client.wav(item, request.duration))
            seed += size
