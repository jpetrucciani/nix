# [`audio.cpp`](https://github.com/0xShug0/audio.cpp) is a high-performance C++ audio inference framework
{ lib
, stdenv
, fetchFromGitHub
, cmake
, ninja
, pkg-config
, python3
, rocmPackages
, cudaPackages
, vulkan-headers
, vulkan-loader
, vulkan-tools
, glslang
, shaderc
, config
, callPackage
, autoAddDriverRunpath
, cudaSupport ? config.cudaSupport or false
, vulkanSupport ? false
, metalSupport ? stdenv.hostPlatform.isDarwin
, rocmSupport ? config.rocmSupport or false
, rocmGpuTargets ? (lib.optionals rocmSupport rocmPackages.clr.gpuTargets)
, strixHaloOptimizations ? (rocmSupport && rocmGpuTargets == [ "gfx1151" ])
, models ? [ ]
}:

assert lib.assertMsg (!(cudaSupport && rocmSupport)) "audio.cpp cannot enable CUDA and ROCm together";
assert lib.assertMsg (!cudaSupport || stdenv.hostPlatform.isLinux) "audio.cpp CUDA support requires Linux";
assert lib.assertMsg
  (!rocmSupport || (stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isx86_64))
  "audio.cpp ROCm support requires x86_64-linux";
assert lib.assertMsg (!metalSupport || stdenv.hostPlatform.isDarwin) "audio.cpp Metal support requires Darwin";

stdenv.mkDerivation (finalAttrs: {
  pname = "audio.cpp";
  version = "0.6.1";

  src = fetchFromGitHub {
    owner = "0xShug0";
    repo = "audio.cpp";
    tag = "release-${finalAttrs.version}";
    hash = "sha256-lvBmBDtTageutl+64rwCDNw4BaVNPPNko2tKyzdsFS4=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    python3
  ]
  ++ lib.optional cudaSupport cudaPackages.cuda_nvcc
  ++ lib.optional cudaSupport autoAddDriverRunpath
  ++ lib.optional rocmSupport rocmPackages.clr;

  buildInputs = lib.optionals vulkanSupport [
    glslang
    shaderc
    vulkan-headers
    vulkan-loader
    vulkan-tools
  ]
  ++ lib.optional cudaSupport cudaPackages.cudatoolkit
  ++ lib.optionals rocmSupport [
    rocmPackages.clr
    rocmPackages.hipblas
    rocmPackages.rocblas
  ];

  cmakeBuildType = "RelWithDebInfo";
  cmakeFlags = [
    (lib.cmakeBool "ENGINE_ENABLE_NATIVE_CPU" false)
    (lib.cmakeBool "ENGINE_ENABLE_LLAMAFILE" true)
    (lib.cmakeBool "ENGINE_ENABLE_CUDA" cudaSupport)
    (lib.cmakeBool "ENGINE_ENABLE_HIP" rocmSupport)
    (lib.cmakeBool "ENGINE_ENABLE_VULKAN" vulkanSupport)
    (lib.cmakeBool "ENGINE_ENABLE_METAL" metalSupport)
  ]
  ++ lib.optionals (models != [ ]) [
    (lib.cmakeFeature "AUDIOCPP_MODEL_SET" "custom")
    (lib.cmakeFeature "AUDIOCPP_MODELS" (lib.concatStringsSep "," models))
  ]
  ++ lib.optional (models == [ ]) (lib.cmakeFeature "AUDIOCPP_MODEL_SET" "full")
  ++ lib.optional stdenv.hostPlatform.isDarwin (lib.cmakeBool "ENGINE_ENABLE_OPENMP" false)
  ++ lib.optional rocmSupport (lib.cmakeFeature "CMAKE_HIP_COMPILER" "${rocmPackages.llvm.clang}/bin/clang")
  ++ lib.optional rocmSupport (lib.cmakeFeature "GPU_TARGETS" (lib.concatStringsSep ";" rocmGpuTargets))
  ++ lib.optional strixHaloOptimizations (lib.cmakeBool "ENGINE_HIP_STRIX_HALO_OPTIMIZATIONS" true);

  env = lib.optionalAttrs rocmSupport {
    ROCM_PATH = toString rocmPackages.clr;
  };

  installPhase = ''
    runHook preInstall

    install -Dm755 bin/audiocpp_cli "$out/bin/audiocpp_cli"
    install -Dm755 bin/audiocpp_server "$out/bin/audiocpp_server"
    install -Dm755 bin/audiocpp_gguf "$out/bin/audiocpp_gguf"
    install -Dm755 "$src/tools/model_manager_v2.py" "$out/bin/audiocpp_model_manager"
    cp -R "$src/model_specs" "$out/model_specs"
    substituteInPlace "$out/bin/audiocpp_model_manager" \
      --replace-fail '#!/usr/bin/env python3' '#!${lib.getExe python3}'

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    "$out/bin/audiocpp_cli" --help >/dev/null
    "$out/bin/audiocpp_cli" --list-devices >/dev/null
    "$out/bin/audiocpp_server" --help >/dev/null
    "$out/bin/audiocpp_model_manager" --help >/dev/null
    "$out/bin/audiocpp_model_manager" list >/dev/null

    runHook postInstallCheck
  '';

  passthru =
    lib.optionalAttrs stdenv.hostPlatform.isLinux
      {
        cuda = callPackage ./audio-cpp.nix {
          inherit models vulkanSupport;
          cudaSupport = true;
          rocmSupport = false;
        };
      }
    // lib.optionalAttrs (stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isx86_64) {
      rocm = callPackage ./audio-cpp.nix {
        inherit models vulkanSupport;
        cudaSupport = false;
        rocmSupport = true;
      };
    };

  meta = {
    description = "High-performance C++ audio inference framework powered by ggml";
    homepage = "https://github.com/0xShug0/audio.cpp";
    changelog = "https://github.com/0xShug0/audio.cpp/releases/tag/release-${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "audiocpp_cli";
    skipBuild = true; # don't ever build this on github actions - it's quite heavy!
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
})
