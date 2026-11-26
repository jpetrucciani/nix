# Stable Audio 3 inference service

Generate sound effects and music, make variations from a reference recording, or regenerate a time range. The service
uses [Stability AI's PyTorch inference library](https://github.com/Stability-AI/stable-audio-3) with the `small-sfx`,
`small-music`, and `medium` checkpoints. It uses CUDA 12.8 wheels, BF16 inference, and Flash Attention 2 for the RTX 5090.

## Run

Use a Hugging Face account with access to the [Small SFX], [Small Music], and [Medium] model repositories. Request access
for the checkpoints you intend to use and set `HF_TOKEN` or sign in through the Hugging Face CLI. Downloads use the
standard Hugging Face cache, which you can relocate with `HF_HOME`.

```sh
nix run .#stable-audio-3.wsl -- --max-batch 4 --max-resident 1
```

Use `.#stable-audio-3` on NixOS. Both package variants use the Python environment from `uv.lock`.

The service defaults to `127.0.0.1:8766`, loads models on demand, and keeps the most recently used model resident. Use
`--eager-model small-sfx` to load it during startup. `--max-resident` controls the number of cached models and
`--queue-slots` bounds the total active and waiting jobs. An unload releases the model and unused CUDA allocations. The
CUDA context stays active until the service exits. Artifacts default to `$XDG_STATE_HOME/stable-audio-3` or
`~/.local/state/stable-audio-3`. Set `STABLE_AUDIO_TOKEN` to require `Authorization: Bearer <token>` on API calls.

## Command line

`stable_audio` sends a prompt to the running service and prints the path of each downloaded clip. By default it
requests a two-second WAV from Small SFX. Use `STABLE_AUDIO_URL` for a different server and `STABLE_AUDIO_TOKEN`
if it requires authentication.

```sh
nix run .#stable_audio -- 'Two golf balls colliding, dry close recording'
nix run .#stable_audio -- --variations 4 --output-dir ./takes 'A golf ball dropping into a putting cup'
nix run .#stable_audio -- --reference collision.wav --noise 0.6 'A brighter version of the collision'
```

Combine `--reference` and `--variations` to request a batch of edits. The server's `--max-batch` limits the number
of clips per request.

## API

Open `http://127.0.0.1:8766/docs` for the interactive documentation and `/openapi.json` for the schema. `/health`,
`/ready`, and `/metrics` expose service status and Prometheus metrics. Lazy readiness verifies CUDA and Flash Attention
at startup. `/v1/models` reports current residency and configured limits.

```sh
base=http://127.0.0.1:8766
curl -fsS "$base/v1/models"
curl -fsS -X POST "$base/v1/models/small-sfx/load"
curl -fsS "$base/v1/audio/generations" -H 'Content-Type: application/json' \
  -d '{"prompt":"Two golf balls colliding, dry close recording","duration":1,"seed":42,"response":"audio"}' \
  -o collision.wav
curl -fsS "$base/v1/audio/generations" -H 'Content-Type: application/json' \
  -d '{"prompt":"A golf ball dropping into a putting cup","duration":2,"variations":4,"processing":{"format":"flac"}}'
curl -fsS "$base/v1/audio/edits" \
  -F 'reference=@collision.wav' \
  -F 'options={"prompt":"A brighter version of the collision","duration":1,"init_noise_level":0.6}'
curl -fsS "$base/v1/audio/inpaint" \
  -F 'reference=@collision.wav' \
  -F 'options={"prompt":"A gentle bounce after impact","duration":1,"start":0.3,"end":0.7}'
curl -fsS -X POST "$base/v1/models/small-sfx/unload"
```

The default response is a manifest with a download link and an original float WAV for each variation. Use
`GET /v1/audio/artifacts/{id}` to download the export, `?file=original` for the original, or `?file=metadata` for the
recorded seed, revision, settings, latency, and memory usage. A single-audio response includes `X-Artifact-Id` and
`X-Seed` headers. The logged seed applies to the entire batch. Reproduce a variation by submitting the same request
with that seed and selecting the same batch index.

WAV, FLAC, and OGG exports support sample-rate conversion, mono or stereo output, fades, silence trimming at −60 dBFS,
DC offset removal, and peak normalization to 0.99. Processing is opt-in. The three post-trained checkpoints use
upstream's fixed guidance defaults. Upstream limits CFG and negative prompts to its base checkpoints.

## Checks and benchmark

Run these commands from the repository root.

```sh
nix shell .#stable-audio-3.uvEnv -c python -m unittest discover -s pkgs/uv/stable-audio-3/tests
nix shell .#stable-audio-3.wsl -c stable-audio-3-benchmark --output ./benchmark-audio
```

Set `STABLE_AUDIO_TEST_GPU=1` to include a Small SFX reference edit in the test run. For GPU tests, include the host
driver directory in `LD_LIBRARY_PATH`. Use `/usr/lib/wsl/lib` on WSL or `/run/opengl-driver/lib` on NixOS.

Start the service with `--max-batch 16` to attempt the full Small SFX and Medium matrix. The CLI measures cold requests
immediately after unload and warm requests with the model resident. It checks downloaded WAV duration and sample rate and
writes `results.jsonl` plus four WAV variations for each of five golf sounds. `--audition-only` produces just the WAV pack.
VRAM figures measure PyTorch allocations. The first cold request can include checkpoint download time.

## Licensing

The [upstream inference code](https://github.com/Stability-AI/stable-audio-3/blob/main/LICENSE) is MIT-licensed. Model
weights are subject to the [Stability AI Community License](https://stability.ai/license) and the terms linked from each
Hugging Face model card. The Community License requires registration for commercial use and applies below Stability
AI's USD 1 million annual revenue threshold. Review the model card terms and Stability AI's
[commercial usage guidance](https://kb.stability.ai/knowledge-base/stable-audio-commerical-and-usage-licensing) before
using the models commercially.

[Small SFX]: https://huggingface.co/stabilityai/stable-audio-3-small-sfx
[Small Music]: https://huggingface.co/stabilityai/stable-audio-3-small-music
[Medium]: https://huggingface.co/stabilityai/stable-audio-3-medium
