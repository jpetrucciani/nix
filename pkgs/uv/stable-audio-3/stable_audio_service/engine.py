import gc
import json
from collections import OrderedDict
from pathlib import Path
from secrets import randbits
from time import perf_counter
from typing import TYPE_CHECKING, NoReturn

from prometheus_client import CollectorRegistry, Counter, Gauge, Histogram

from .audio import decode_reference, save_batch
from .schema import Edit, Generation, Inpaint, Manifest, ModelName

if TYPE_CHECKING:
    from stable_audio_3 import StableAudioModel

CHECKPOINTS: dict[ModelName, str] = {
    "small-sfx": "05ca3857881c94a2b84026b1111c537d78f5f9f0",
    "small-music": "8bdfb53c6b0fbc62113cd571fd37373efe15fa14",
    "medium": "d4d3579395a8ac0df4ab13b5b1d7138ce7290f81",
}


class GPUOutOfMemory(RuntimeError):
    pass


class CheckpointUnavailable(RuntimeError):
    pass


class Engine:
    def __init__(
        self, artifact_dir: Path, max_resident: int, registry: CollectorRegistry
    ) -> None:
        self.artifact_dir = artifact_dir
        self.max_resident = max_resident
        self.models: OrderedDict[ModelName, StableAudioModel] = OrderedDict()
        self.inference_time = Histogram(
            "stable_audio_inference_seconds",
            "CUDA generation latency",
            ["model"],
            registry=registry,
        )
        self.memory_allocated = Gauge(
            "stable_audio_gpu_allocated_bytes",
            "PyTorch CUDA allocations",
            registry=registry,
        )
        self.memory_reserved = Gauge(
            "stable_audio_gpu_reserved_bytes",
            "PyTorch CUDA allocator reservations",
            registry=registry,
        )
        self.memory_free = Gauge(
            "stable_audio_gpu_free_bytes", "Free GPU memory", registry=registry
        )
        self.ooms = Counter(
            "stable_audio_cuda_ooms", "CUDA out-of-memory errors", registry=registry
        )

    def start(self) -> None:
        import torch

        if not torch.cuda.is_available():
            raise RuntimeError("Stable Audio 3 requires a working CUDA GPU")
        from flash_attn import flash_attn_func

        probe = torch.ones((1, 16, 1, 64), device="cuda", dtype=torch.bfloat16)
        flash_attn_func(probe, probe, probe)
        torch.cuda.synchronize()
        del probe
        self.artifact_dir.mkdir(parents=True, exist_ok=True)
        self.release_cache()

    def snapshot_memory(self) -> None:
        import torch

        self.memory_allocated.set(torch.cuda.memory_allocated())
        self.memory_reserved.set(torch.cuda.memory_reserved())
        self.memory_free.set(torch.cuda.mem_get_info()[0])

    def release_cache(self) -> None:
        import torch

        gc.collect()
        torch.cuda.empty_cache()
        self.snapshot_memory()

    def load(self, name: ModelName) -> float:
        import torch
        from huggingface_hub import snapshot_download
        from huggingface_hub.errors import GatedRepoError, LocalEntryNotFoundError
        from stable_audio_3 import StableAudioModel
        from stable_audio_3.loading_utils import load_diffusion_cond
        from stable_audio_3.model_configs import models

        if name in self.models:
            self.models.move_to_end(name)
            return 0.0

        start = perf_counter()
        checkpoint = models[name]
        try:
            snapshot = Path(
                snapshot_download(
                    repo_id=checkpoint.repo_id,
                    revision=CHECKPOINTS[name],
                    allow_patterns=[
                        checkpoint.ckpt_path,
                        checkpoint.config_path,
                        "t5gemma-b-b-ul2/*",
                    ],
                )
            )
        except (GatedRepoError, LocalEntryNotFoundError) as exc:
            raise CheckpointUnavailable(
                f"Cannot fetch {name} from Hugging Face. Check model access, credentials, and network availability."
            ) from exc

        config = json.loads(
            (snapshot / checkpoint.config_path).read_text(encoding="utf-8")
        )
        # Upstream's from_pretrained resolves main. Use its loader with the pinned
        # checkpoint and matching text encoder from the same local snapshot.
        for conditioner in config["model"]["conditioning"]["configs"]:
            if conditioner["type"] == "t5gemma":
                conditioner["config"].update(
                    model_path=str(snapshot / "t5gemma-b-b-ul2"), subfolder=None
                )

        if len(self.models) == self.max_resident:
            self.unload(next(iter(self.models)))
        try:
            # FP16 overflows in the diffusion sampler on some reference edits.
            model = load_diffusion_cond(
                config,
                str(snapshot / checkpoint.ckpt_path),
                device="cuda",
                model_half=False,
            ).to(dtype=torch.bfloat16)
            model.use_lora = False
            model.lora_names = []
            self.models[name] = StableAudioModel(model, config, "cuda", True)
            self.snapshot_memory()
            return perf_counter() - start
        except torch.cuda.OutOfMemoryError:
            pass
        self.fail_oom(name)

    def unload(self, name: ModelName) -> None:
        if name in self.models:
            del self.models[name]
            self.release_cache()

    def fail_oom(self, name: ModelName) -> NoReturn:
        # Drop the model as well as the failed call's tensors. Upstream moves
        # the text encoder to CUDA on the first request and can fail midway.
        self.models.pop(name, None)
        self.ooms.inc()
        self.release_cache()
        raise GPUOutOfMemory(
            "CUDA ran out of memory. Reduce batch size or duration, or unload other models."
        )

    def generate(self, request: Generation, reference: bytes | None = None) -> Manifest:
        import torch

        audio_args = {}
        if reference is not None:
            rate, samples = decode_reference(reference)
            source = (rate, torch.from_numpy(samples.T.copy()))
            if isinstance(request, Edit):
                audio_args = {
                    "init_audio": source,
                    "init_noise_level": request.init_noise_level,
                }
            elif isinstance(request, Inpaint):
                audio_args = {
                    "inpaint_audio": source,
                    "inpaint_mask_start_seconds": request.start,
                    "inpaint_mask_end_seconds": request.end,
                }

        load_seconds = self.load(request.model)
        seed = request.seed if request.seed is not None else randbits(63)
        try:
            return self.generate_batch(
                request, reference, audio_args, seed, load_seconds
            )
        except torch.cuda.OutOfMemoryError:
            pass
        self.fail_oom(request.model)

    def generate_batch(
        self,
        request: Generation,
        reference: bytes | None,
        audio_args: dict[str, object],
        seed: int,
        load_seconds: float,
    ) -> Manifest:
        import numpy as np
        import torch

        model = self.models[request.model]
        torch.cuda.reset_peak_memory_stats()
        start = perf_counter()
        batch = (
            model.generate(
                prompt=request.prompt,
                duration=request.duration,
                steps=request.steps,
                batch_size=request.variations,
                seed=seed,
                **audio_args,
            )
            .transpose(1, 2)
            .cpu()
            .numpy()
        )
        inference_seconds = perf_counter() - start
        rate = model.model.sample_rate
        if (
            batch.shape[:2] != (request.variations, int(request.duration * rate))
            or not np.isfinite(batch).all()
        ):
            raise RuntimeError("Upstream returned invalid audio")
        self.snapshot_memory()
        self.inference_time.labels(request.model).observe(inference_seconds)
        return save_batch(
            self.artifact_dir,
            batch,
            rate,
            request,
            seed=seed,
            revision=CHECKPOINTS[request.model],
            reference=reference,
            load_seconds=load_seconds,
            inference_seconds=inference_seconds,
            peak_vram_bytes=torch.cuda.max_memory_allocated(),
            resident_vram_bytes=torch.cuda.memory_allocated(),
        )
