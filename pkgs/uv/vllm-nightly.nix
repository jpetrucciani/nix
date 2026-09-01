# [vllm](https://github.com/vllm-project/vllm) is a high-throughput and memory-efficient inference and serving engine for LLMs
{ vllm, vllm-nightly, version ? "2026-02-02-nightly", lockHash ? "sha256-/qj9+4zx7DIoMmXUnVwmJUN620Jml9x3ygAjUohjULE=", isWSL ? false }:
(vllm.override { inherit isWSL version lockHash; }).overrideAttrs (old: {
  pname = "vllm-nightly";
  passthru = {
    wsl = vllm-nightly.override { isWSL = true; };
  };
  meta = old.meta // {
    platforms = [ "x86_64-linux" ];
  };
})
