# ai

This directory contains packages that are related to the new wave of AI/LLM popularity!

---

## In this directory

### [agent-deck.nix](./agent-deck.nix)

[`agent-deck`](https://github.com/asheshgoplani/agent-deck) is a terminal session manager for AI coding agents. One TUI for Claude, Gemini, OpenCode, Codex, and more

### [audio-cpp.nix](./audio-cpp.nix)

[`audio.cpp`](https://github.com/0xShug0/audio.cpp) is a high-performance C++ audio inference framework powered by ggml

The default build uses CPU inference on Linux and Metal on macOS. CUDA and ROCm builds are available as
`audio-cpp.cuda` and `audio-cpp.rocm`, respectively.

### [clef-flash-server.nix](./clef-flash-server.nix)

An NF4 CUDA server for Cloudflare Clef-Flash's native typed decision API. The implementation and build setup
live in [clef-flash-server](https://github.com/jpetrucciani/clef-flash-server); this package fetches
[v0.1.0](https://github.com/jpetrucciani/clef-flash-server/releases/tag/v0.1.0) with Python 3.13 by default.
The release includes fast CUDA kernels and automatic batching. Build with
`nix build -f default.nix clef-flash-server`; WSL driver support is available as `clef-flash-server.wsl`.

### [codex-latest.nix](./codex-latest.nix)

Latest packaged Codex release with its matching Rusty V8 archive and generated binding. Run `nix run .#codex-latest.updateScript` to refresh and validate it.

### [codex-nix-daemon.patch](./codex-nix-daemon.patch)

Makes the Codex daemon use the Nix-packaged binary and disables its automatic updater.

### [deepseek-harness.nix](./deepseek-harness.nix)

[`deepseek-harness`](https://github.com/deepseek-ai/deepseek-harness) is an open-source agent harness developed by DeepSeek AI

### [genai-toolbox.nix](./genai-toolbox.nix)

[`genai-toolbox`](https://github.com/googleapis/genai-toolbox) is an open source MCP server for databases, designed and built with enterprise-quality and production-grade usage in mind

### [geode.nix](./geode.nix)

geode is an experimental semantic indexing tool

Run `nix run .#geode.refreshScript -- VERSION` to refresh every platform artifact. Once the plain-text
`https://static.g7c.us/geode/latest` endpoint is published, `VERSION` may be omitted.

### [geode.json](./geode.json)

Pinned release version and platform hashes consumed by the package.

### [h2o-lightning-4b](./h2o-lightning-4b/)

Helpers that patch the decision shim to reject oversized input and verify context limits against a running vLLM backend.

### [h2o-lightning-4b.nix](./h2o-lightning-4b.nix)

[`H2O-Lightning-4B`](https://huggingface.co/h2oai/h2o-lightning-4b) is a decision model exposed through a
Jev-compatible API. This derivation combines the existing [`vllm`](../uv/vllm.nix) package with upstream's
Python shim, `h2o_lightning_shim.py`, which uses only the standard library, and its prompt and calibration config. It supports
`choice` questions with option probabilities, yes/no questions (`noul`), and ordinal `score` questions,
including image inputs.

The default package uses native Linux vLLM; `h2o-lightning-4b.wsl` uses `vllm.wsl` and its WSL CUDA driver setup.
Both pin the shim, config, and default model revision to upstream v1.2.1
(`542e9eff5ce7e5d69eb457fbe54abb535992ab20`). Nix packages the launcher and shim; vLLM downloads model weights
into the Hugging Face cache at runtime. Use `--model /path/to/h2o-lightning-4b` to serve a local model directory.
Serving the model requires an NVIDIA GPU with enough memory for the weights and context cache.

Build or run from the repository root:

```bash
# Native Linux
nix build path:.#h2o-lightning-4b
nix run path:.#h2o-lightning-4b

# WSL
nix build path:.#h2o-lightning-4b.wsl
nix run path:.#h2o-lightning-4b.wsl
```

The launcher starts a private vLLM backend on `127.0.0.1:8000` and the decision API on `127.0.0.1:8741`.
It stops both processes when interrupted, and stops the remaining process if either exits. Point a Jev-compatible
client at the shim's base URL, `http://127.0.0.1:8741`; decisions use `POST /v1/systemone` and model discovery uses
`GET /v1/models`. `GET /health` returns HTTP 200 once the shim has verified the backend's model and label tokens.

```bash
curl --fail http://127.0.0.1:8741/health

curl --fail http://127.0.0.1:8741/v1/systemone \
  -H 'Content-Type: application/json' \
  -d '{
    "state": "Checkout returns HTTP 500 for every customer. No orders are completing.",
    "questions": {
      "priority": {
        "type": "choice",
        "instructions": "Which priority fits this incident?",
        "criteria": {
          "p1": "A revenue path is fully down",
          "p2": "Degraded but still working",
          "p3": "Cosmetic issue"
        }
      }
    }
  }'
```

Read the selected option from `answers.priority.choice` and the distribution from
`answers.priority.probabilities`. Wait for `/health` to succeed before submitting decisions.

The wrapper accepts these flags and environment variables:

| Flag                       | Environment variable | Default                                              |
| -------------------------- | -------------------- | ---------------------------------------------------- |
| `--host`                   | `SHIM_HOST`          | `127.0.0.1`, decision API bind address               |
| `--port`                   | `SHIM_PORT`          | `8741`, decision API port                            |
| `--vllm-port`              | `VLLM_PORT`          | `8000`, private backend port                         |
| `--vllm-url`               | `SHIM_VLLM`          | Unset; starts a managed backend                      |
| `--model`                  | `MODEL`              | `h2oai/h2o-lightning-4b`                             |
| `--revision`               | `MODEL_REVISION`     | Pinned model revision above                          |
| `--max-model-len`          | `MAX_LEN`            | `40960`                                              |
| `--gpu-memory-utilization` | `GPU_UTIL`           | `0.90`                                               |
| `--config`                 | `SHIM_CONFIG`        | Pinned upstream `serve_config.json` in the Nix store |

To expose the decision API on other interfaces, pass `--host 0.0.0.0`; the managed vLLM backend stays on loopback.
Pass additional vLLM arguments after `--`:

```bash
nix run path:.#h2o-lightning-4b.wsl -- --gpu-memory-utilization 0.80 -- --tensor-parallel-size 2
```

If the model is already served as `h2oai/h2o-lightning-4b`, run only the shim with `--vllm-url`:

```bash
nix run path:.#h2o-lightning-4b -- --vllm-url http://127.0.0.1:8000
```

This mode leaves backend lifecycle management to the caller and rejects additional vLLM arguments.
The launcher defaults `VLLM_USE_FLASHINFER_SAMPLER=0`, matching upstream: decisions read label log-probabilities
without sampling. Set that variable explicitly to override it.

### [jeeves.nix](./jeeves.nix)

[`jeeves`](https://github.com/robinovitch61/jeeves) is an AI agent conversation history browser

### [kimi-code.nix](./kimi-code.nix)

[`kimi-code`](https://github.com/MoonshotAI/kimi-code) is an AI coding agent for the terminal

### [llama-cpp-latest.nix](./llama-cpp-latest.nix)

Latest llama.cpp release with the web UI dependency set. Run `nix run .#llama-cpp-latest.updateScript` to refresh and validate it.

### [maestro-go.nix](./maestro-go.nix)

[`maestro`](https://github.com/pluja/maestro) converts natural language instructions into cli commands with LLMs

### [whisper-cpp-latest.nix](./whisper-cpp-latest.nix)

Latest semver whisper.cpp release. Run `nix run .#whisper-cpp-latest.updateScript` to refresh and validate it.
CUDA builds are available as `whisper-cpp-cuda` and `whisper-cpp-cuda-latest`.
