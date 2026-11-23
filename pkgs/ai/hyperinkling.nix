{ docker, lib, writeShellApplication }:
let
  version = "0.1.2";
  # The upstream binary includes the patched vLLM and CUDA kernels for sm_86.
  image = "ghcr.io/pento95/hyperinkling@sha256:acddfcc2de87a989f23984fb0b8aaeacbea3024e786e6f5d737c788807b04ca8";
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
