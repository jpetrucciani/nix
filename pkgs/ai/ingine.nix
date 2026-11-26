# [Ingine](https://github.com/satellitedown/inkling-2-mini-abliterated-ingine) serves Inkling 2 Mini on Blackwell.
{ lib
, hax
, fetchFromGitHub
, cmake
, ninja
, autoAddDriverRunpath
, cudaPackages_13_4
}:
let
  # Match the upstream toolkit for the DSpark FP8 conversions and L2 cache hints.
  cudaPackages = cudaPackages_13_4;
in
cudaPackages.backendStdenv.mkDerivation (finalAttrs: {
  pname = "ingine";
  version = "unstable-2026-11-22";

  src = fetchFromGitHub {
    owner = "satellitedown";
    repo = "inkling-2-mini-abliterated-ingine";
    rev = "556acc7cf42749536684854a6df820e41258f929";
    hash = "sha256-Lhkv96bX4/IOeFWLHpo5WXaAZKwGcI3obARaXdLaQhg=";
  };

  strictDeps = true;
  nativeBuildInputs = [ cmake ninja autoAddDriverRunpath cudaPackages.cuda_nvcc ];
  buildInputs = with cudaPackages; [ cuda_cudart nvtx cccl libcublas ];

  cmakeDir = "../native";
  cmakeFlags = [
    (lib.cmakeFeature "CMAKE_CUDA_ARCHITECTURES" "120a")
    (lib.cmakeBool "INGINE_BUILD_TESTS" false)
  ];
  ninjaFlags = [ "ingine-serve" ];

  installPhase = ''
    runHook preInstall
    install -Dm755 apps/serve/ingine-serve "$out/bin/ingine-serve"
    install -Dm644 ../runtime-manifest.json "$out/share/ingine/runtime-manifest.json"
    install -Dm644 -t "$out/share/licenses/ingine" ../LICENSE ../NOTICE
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/ingine-serve" --help >/dev/null
    runHook postInstallCheck
  '';

  passthru.wsl = hax.wrapWslCuda {
    package = finalAttrs.finalPackage;
    programs = [ "ingine-serve" ];
  };

  meta = {
    description = "OpenAI-compatible Inkling 2 Mini inference server for NVIDIA Blackwell (sm_120a)";
    homepage = "https://github.com/satellitedown/inkling-2-mini-abliterated-ingine";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "ingine-serve";
    platforms = [ "x86_64-linux" ];
    skipBuild = true; # Keep CUDA builds out of the aggregate CI build.
  };
})
