# [vllm](https://github.com/vllm-project/vllm) is a high-throughput and memory-efficient inference and serving engine for LLMs
{ vllm, vllm-nightly, version ? "2025-11-28-nightly", lockHash ? "sha256-1KYkrLJMJaBApbakAqmreRAwSu5LhJxu5DJRohMfr8M=", isWSL ? false }:
(vllm.override { inherit isWSL version lockHash; }).overrideAttrs (_: {
  pname = "vllm-nightly";
  passthru = {
    wsl = vllm-nightly.override { isWSL = true; };
  };
})
