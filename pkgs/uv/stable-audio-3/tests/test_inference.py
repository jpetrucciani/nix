import os
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory

import numpy as np
import soundfile as sf
from prometheus_client import CollectorRegistry

from stable_audio_service.engine import Engine
from stable_audio_service.schema import Edit, Generation


@unittest.skipUnless(
    os.environ.get("STABLE_AUDIO_TEST_GPU") == "1",
    "requires CUDA and Small SFX checkpoint access",
)
class InferenceTests(unittest.TestCase):
    def test_small_sfx_edit_remains_finite(self) -> None:
        with TemporaryDirectory() as directory:
            root = Path(directory)
            engine = Engine(root, 1, CollectorRegistry())
            engine.start()
            try:
                batch = engine.generate(
                    Generation(
                        prompt="Two golf balls colliding, isolated close mic",
                        duration=0.5,
                        seed=42,
                        variations=2,
                    )
                )
                batch_id, index = batch.artifacts[1].id.split(".")
                reference = (root / batch_id / f"{index}.original.wav").read_bytes()
                edit = engine.generate(
                    Edit(
                        prompt="A slightly brighter collision",
                        duration=0.5,
                        seed=42,
                        init_noise_level=0.7,
                    ),
                    reference,
                )
                batch_id, index = edit.artifacts[0].id.split(".")
                samples, rate = sf.read(root / batch_id / f"{index}.original.wav")
                self.assertEqual((len(samples), rate), (22050, 44100))
                self.assertTrue(np.isfinite(samples).all())
            finally:
                engine.unload("small-sfx")
