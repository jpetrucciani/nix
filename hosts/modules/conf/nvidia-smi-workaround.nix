{ config, lib, ... }:
{
  hardware.nvidia.package = lib.mkDefault (config.boot.kernelPackages.nvidiaPackages.stable.overrideAttrs {
    postInstall = ''
      # patchelf 0.19.2 overlaps nvidia-smi's writable and read-only LOAD segments.
      # Repatch the vendor binary with enough padding to keep them separate.
      install -m755 "$bin/origBin/nvidia-smi" "$bin/bin/nvidia-smi"
      patchelf --page-size 65536 \
        --set-interpreter "$(cat "$NIX_CC/nix-support/dynamic-linker")" \
        --set-rpath "$out/lib:$libPath" "$bin/bin/nvidia-smi"
    '';
  });
}
