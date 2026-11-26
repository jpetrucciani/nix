import unittest
from io import BytesIO
from pathlib import Path
from tempfile import TemporaryDirectory

import numpy as np
import soundfile as sf

from stable_audio_service.audio import InvalidAudio, decode_reference, save_batch
from stable_audio_service.schema import Edit, Manifest, Processing


class AudioTests(unittest.TestCase):
    def test_exports_processed_audio_and_preserves_original(self) -> None:
        reference = BytesIO()
        signal = np.zeros((800, 2), dtype=np.float32)
        signal[200:600, :] = 0.125
        sf.write(reference, signal, 8000, format="WAV", subtype="FLOAT")
        rate, samples = decode_reference(reference.getvalue())
        request = Edit(
            prompt="A hollow knock",
            init_noise_level=0.25,
            processing=Processing(
                format="flac", trim_silence=True, channels=1, sample_rate=16000
            ),
        )
        with TemporaryDirectory() as directory:
            root = Path(directory)
            manifest = save_batch(
                root,
                samples[None, :, :],
                rate,
                request,
                seed=42,
                revision="abc",
                reference=reference.getvalue(),
                load_seconds=0,
                inference_seconds=1,
                peak_vram_bytes=100,
                resident_vram_bytes=50,
            )
            item = manifest.artifacts[0]
            batch = root / item.id.split(".")[0]
            original, original_rate = sf.read(batch / "0.original.wav", dtype="float32")
            output = sf.info(batch / "0.flac")
            saved = Manifest.model_validate_json((batch / "manifest.json").read_bytes())

        np.testing.assert_array_equal(original, signal)
        self.assertEqual(original_rate, 8000)
        self.assertEqual(
            (output.frames, output.samplerate, output.channels), (800, 16000, 1)
        )
        self.assertEqual(saved, manifest)
        self.assertEqual(saved.artifacts[0].seed, 42)
        self.assertIsInstance(saved.artifacts[0].request, Edit)

    def test_rejects_unreadable_reference(self) -> None:
        with self.assertRaises(InvalidAudio):
            decode_reference(b"broken recording")
