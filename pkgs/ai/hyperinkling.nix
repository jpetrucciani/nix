{ docker, lib, writeShellApplication }:
let
  version = "0.1.3";
  # The upstream binary includes the patched vLLM and CUDA kernels for sm_86.
  image = "ghcr.io/pento95/hyperinkling@sha256:e6db7291d84c32821789d0e56c38fdd935fbe6375f6057dcf7f64302455c7878";
in
writeShellApplication {
  name = "hyperinkling";
  passthru = { inherit version image; };
  runtimeInputs = [ docker ];
  text = ''
    case "''${1:-}" in
      ""|-h|--help)
        echo "Usage: hyperinkling [DOCKER_RUN_OPTION ...]"
        echo "Mount the checkpoint, set MODEL to its container path, and select one sm_86 GPU with --device."
        echo "Use --image to print the pinned image reference."
        ;;
      --image) echo ${lib.escapeShellArg image} ;;
      --version) echo "hyperinkling ${version}" ;;
      *) exec docker run --rm --platform linux/amd64 "$@" ${lib.escapeShellArg image} ;;
    esac
  '';
  meta = {
    description = "Launch the pinned HyperInkling vLLM image for Inkling 2 Mini on NVIDIA sm_86";
    homepage = "https://github.com/Pento95/HyperInkling";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
  };
}
