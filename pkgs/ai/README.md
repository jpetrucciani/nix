# ai

This directory contains packages that are related to the new wave of AI/LLM popularity!

---

## In this directory

### [alpaca-cpp.nix](./alpaca-cpp.nix)

[`alpaca.cpp`](https://github.com/antimatter15/alpaca.cpp) is a popular fork of [`llama.cpp`](https://github.com/ggerganov/llama.cpp) that is tuned for specifically running [Alpaca](https://crfm.stanford.edu/2023/03/13/alpaca.html) models.

### [chatbot-ui.nix](./chatbot-ui.nix)

[`chatbot-ui`](https://github.com/mckaywrigley/chatbot-ui) is a popular frontend for OpenAI compliant APIs. It is designed to look similar to OpenAI's ChatGPT UI. I use this in combination with [`gpt-llama-cpp`](https://github.com/keldenl/gpt-llama.cpp) to run models locally as if they were OpenAI apis!

### [gpt-llama-cpp.nix](./gpt-llama-cpp.nix)

[`gpt-llama-cpp`](https://github.com/keldenl/gpt-llama.cpp) is a llama.cpp drop-in replacement for OpenAI's GPT endpoints, allowing GPT-powered apps to run off local llama.cpp models instead of OpenAI. I use this and the above [`chatbot-ui`](https://github.com/mckaywrigley/chatbot-ui) to self host a ChatGPT alternative with local LLM models!

### [llama-cpp.nix](./llama-cpp.nix)

[`llama.cpp`](https://github.com/ggerganov/llama.cpp) is a port of [Facebook's LLaMA](https://ai.facebook.com/blog/large-language-model-llama-meta-ai/) model in C/C++

### [llm.nix](./llm.nix)

[`llm`](https://github.com/rustformers/llm) is a port of [`llama.cpp`](https://github.com/ggerganov/llama.cpp) in rust!

### [whisper-cpp.nix](./whisper-cpp.nix)

[`whisper.cpp`](https://github.com/ggerganov/whisper.cpp) is a port of [OpenAI's Whisper](https://openai.com/research/whisperg) model in C/C++
