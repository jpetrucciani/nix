import hashlib
from io import BytesIO
from math import gcd
from pathlib import Path
from tempfile import TemporaryDirectory
from uuid import uuid4

import numpy as np
import soundfile as sf
from numpy.typing import NDArray
from scipy.signal import resample_poly

from .schema import Artifact, Generation, Manifest, Processing

Audio = NDArray[np.float32]
SUBTYPES = {"wav": "FLOAT", "flac": "PCM_24", "ogg": "VORBIS"}
MAX_UPLOAD_BYTES = 32 * 1024**2


class InvalidAudio(ValueError):
    pass


def decode_reference(data: bytes) -> tuple[int, Audio]:
    try:
        with sf.SoundFile(BytesIO(data)) as source:
            rate = source.samplerate
            if source.channels not in (1, 2) or not 8000 <= rate <= 192000:
                raise InvalidAudio(
                    "reference audio must be mono or stereo at 8–192 kHz"
                )
            if not 0 < source.frames <= 120 * rate:
                raise InvalidAudio(
                    "reference audio must be nonempty and at most 120 seconds"
                )
            samples = source.read(dtype="float32", always_2d=True)
    except sf.LibsndfileError as exc:
        raise InvalidAudio("could not decode reference audio") from exc
    if samples.size == 0 or not np.isfinite(samples).all():
        raise InvalidAudio("reference audio must contain finite samples")
    return rate, samples


def process(samples: Audio, rate: int, options: Processing) -> tuple[Audio, int]:
    output = samples.copy()
    if options.remove_dc:
        output -= output.mean(axis=0)
    if options.trim_silence:
        audible = np.flatnonzero(np.any(np.abs(output) > 0.001, axis=1))
        if audible.size:
            output = output[audible[0] : audible[-1] + 1]
    if options.channels == 1:
        output = output.mean(axis=1, keepdims=True)
    elif options.channels == 2 and output.shape[1] == 1:
        output = np.repeat(output, 2, axis=1)
    if options.sample_rate is not None and options.sample_rate != rate:
        divisor = gcd(options.sample_rate, rate)
        output = resample_poly(
            output, options.sample_rate // divisor, rate // divisor, axis=0
        )
        rate = options.sample_rate

    fade_in = min(round(options.fade_in * rate), len(output))
    fade_out = min(round(options.fade_out * rate), len(output))
    if fade_in:
        output[:fade_in] *= np.linspace(0, 1, fade_in, dtype=np.float32)[:, None]
    if fade_out:
        output[-fade_out:] *= np.linspace(1, 0, fade_out, dtype=np.float32)[:, None]
    if options.peak_normalize:
        peak = np.max(np.abs(output))
        if peak > 0:
            output *= 0.99 / peak
    return output, rate


def save_batch(
    root: Path,
    batch: Audio,
    rate: int,
    request: Generation,
    *,
    seed: int,
    revision: str,
    reference: bytes | None,
    load_seconds: float,
    inference_seconds: float,
    peak_vram_bytes: int,
    resident_vram_bytes: int,
) -> Manifest:
    batch_id = uuid4().hex
    reference_sha256 = (
        hashlib.sha256(reference).hexdigest() if reference is not None else None
    )
    artifacts: list[Artifact] = []
    with TemporaryDirectory(dir=root, prefix=".generating-") as staging:
        stage = Path(staging)
        audio_format = request.processing.format
        for index, samples in enumerate(batch):
            artifact_id = f"{batch_id}.{index}"
            url = f"/v1/audio/artifacts/{artifact_id}"
            sf.write(stage / f"{index}.original.wav", samples, rate, subtype="FLOAT")
            output, output_rate = process(samples, rate, request.processing)
            sf.write(
                stage / f"{index}.{audio_format}",
                output,
                output_rate,
                subtype=SUBTYPES[audio_format],
            )
            artifacts.append(
                Artifact(
                    id=artifact_id,
                    download_url=url,
                    original_url=f"{url}?file=original",
                    format=audio_format,
                    frames=len(output),
                    sample_rate=output_rate,
                    channels=output.shape[1],
                    original_frames=len(samples),
                    original_sample_rate=rate,
                    seed=seed,
                    batch_index=index,
                    checkpoint_revision=revision,
                    request=request,
                    reference_sha256=reference_sha256,
                    load_seconds=load_seconds,
                    inference_seconds=inference_seconds,
                    peak_vram_bytes=peak_vram_bytes,
                    resident_vram_bytes=resident_vram_bytes,
                )
            )
        manifest = Manifest(artifacts=artifacts)
        (stage / "manifest.json").write_text(
            manifest.model_dump_json(), encoding="utf-8"
        )
        stage.rename(root / batch_id)
    return manifest
