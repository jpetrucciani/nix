# [Maya Inkling Mini](https://github.com/alesha-pro/maya-inkling-mini) serves Inkling 2 Mini from GGUF with CUDA.
{ maya-inkling-mini
, lib
, stdenv
, stdenvNoCC
, fetchFromGitHub
, cmake
, ninja
, makeWrapper
, autoAddDriverRunpath
, python312
, cudaPackages_13_0
, cudaArchitectures ? [ "86" ]
, isWSL ? false
}:
let
  version = "1.1.70-unstable-2026-11-22";
  src = fetchFromGitHub {
    owner = "alesha-pro";
    repo = "maya-inkling-mini";
    rev = "cc41ab12af88e8c57b0f36250997f28f8763a3cf";
    hash = "sha256-VB8KpyPiPewAQLhmR1fvYWHXMZgPGxRLqscS7M3K1pI=";
  };
  cudaPackages = cudaPackages_13_0;
  driverWrapperArgs = lib.escapeShellArgs (lib.optionals isWSL [
    "--prefix"
    "LD_LIBRARY_PATH"
    ":"
    "/usr/lib/wsl/lib"
    "--prefix"
    "PATH"
    ":"
    "/usr/lib/wsl/lib"
  ]);
  python = python312.withPackages (ps: with ps; [
    jinja2
    jsonschema
    numpy
    pillow
    psutil
    pyyaml
    regex
    requests
    tqdm
  ]);
  meta = {
    description = "Project Maya CUDA inference server for Inkling 2 Mini";
    homepage = "https://github.com/alesha-pro/maya-inkling-mini";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "maya-serve";
    platforms = [ "x86_64-linux" ];
    skipBuild = true; # Keep CUDA builds out of the aggregate CI build.
  };
  engine = cudaPackages.backendStdenv.mkDerivation {
    pname = "maya-ik2";
    inherit src version;

    strictDeps = true;
    nativeBuildInputs = [ cmake ninja autoAddDriverRunpath cudaPackages.cuda_nvcc ];
    buildInputs = with cudaPackages; [ cuda_cudart cccl libcublas ];

    cmakeFlags = [
      (lib.cmakeBool "STRATA_ENABLE_CUDA" true)
      (lib.cmakeBool "STRATA_PORTABLE" true)
      (lib.cmakeBool "STRATA_BUILD_TESTS" false)
      # maya-ik2 has its own CPU kernels. The other engines would fetch ggml.
      (lib.cmakeBool "STRATA_NATIVE_EXPERTS" false)
      (lib.cmakeFeature "CMAKE_CUDA_ARCHITECTURES" (lib.concatStringsSep ";" cudaArchitectures))
    ];
    ninjaFlags = [ "maya-ik2" ];

    installPhase = ''
      runHook preInstall
      install -Dm755 maya-ik2 "$out/bin/maya-ik2"
      runHook postInstall
    '';

    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck
      # Without a model the CLI prints usage before doing any GPU work.
      if LD_LIBRARY_PATH="${cudaPackages.cuda_cudart}/lib/stubs" "$out/bin/maya-ik2" >usage.txt 2>&1; then
        exit 1
      fi
      grep -F 'usage: maya-ik2' usage.txt
      runHook postInstallCheck
    '';

    meta = meta // { mainProgram = "maya-ik2"; };
  };
  visionEncoder = cudaSupport: (if cudaSupport then cudaPackages.backendStdenv else stdenv).mkDerivation {
    pname = if cudaSupport then "maya-vision-cuda" else "maya-vision";
    inherit src version;

    strictDeps = true;
    nativeBuildInputs = [ cmake ninja ] ++ lib.optionals cudaSupport [ autoAddDriverRunpath cudaPackages.cuda_nvcc ];
    buildInputs = lib.optionals cudaSupport (with cudaPackages; [ cuda_cudart cuda_nvml_dev cccl libcublas ]);
    cmakeDir = "../tools/vision";
    cmakeFlags = [
      (lib.cmakeBool "STRATA_PORTABLE" true)
      (lib.cmakeBool "GGML_CCACHE" false)
      (lib.cmakeFeature "LLAMA_DIR" (toString (fetchFromGitHub {
        owner = "ggml-org";
        repo = "llama.cpp";
        # b12590 is the mtmd revision Maya documents for the Inkling image tower.
        rev = "34ff2e047ce520b1d83bd274bf3ff0bfbc72a69b";
        hash = "sha256-NEhdB5Ziy2K6PWaG7pch2U55f2sMPb10x360+zhZ4qo=";
      })))
    ] ++ lib.optionals cudaSupport [
      (lib.cmakeBool "STRATA_VISION_CUDA" true)
      (lib.cmakeFeature "CMAKE_CUDA_ARCHITECTURES" (lib.concatStringsSep ";" cudaArchitectures))
    ];
    ninjaFlags = [ "maya-vision" ];

    installPhase = ''
      runHook preInstall
      install -Dm755 bin/maya-vision "$out/bin/maya-vision"
      runHook postInstall
    '';

    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck
      ${lib.optionalString cudaSupport ''export LD_LIBRARY_PATH="${cudaPackages.cuda_cudart}/lib/stubs"''}
      if "$out/bin/maya-vision" >usage.txt 2>&1; then
        exit 1
      fi
      grep -F 'usage: maya-vision' usage.txt
      runHook postInstallCheck
    '';

    meta = meta // {
      description = "${if cudaSupport then "CUDA" else "CPU"} image encoder for Maya Inkling 2 Mini";
      mainProgram = "maya-vision";
    };
  };
in
stdenvNoCC.mkDerivation {
  pname = "maya-inkling-mini";
  inherit src version meta;

  strictDeps = true;
  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    maya="$out/share/maya-inkling-mini"
    mkdir -p "$maya"
    cp -r serve tools ref data VERSION "$maya/"
    install -Dm644 LICENSE "$out/share/licenses/maya-inkling-mini/LICENSE"

    makeWrapper ${lib.getExe engine} "$out/bin/maya-ik2" ${driverWrapperArgs}
    makeWrapper ${lib.getExe python} "$out/bin/maya-serve" \
      ${driverWrapperArgs} \
      --add-flags "-B $maya/serve/server.py --engine maya" \
      --set MAYA_UPDATE_CHECK 0
    makeWrapper ${lib.getExe python} "$out/bin/maya-prepare" \
      --add-flags "-B $maya/tools/strata_tokenizer.py --chat-template $maya/tools/ik2/chat_template.jinja"

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/maya-serve" --help >/dev/null
    "$out/bin/maya-prepare" --help >/dev/null
    runHook postInstallCheck
  '';

  passthru = {
    inherit engine cudaArchitectures;
    vision = visionEncoder false;
    visionCuda = visionEncoder true;
    wsl = maya-inkling-mini.override { inherit cudaArchitectures; isWSL = true; };
    ampere = maya-inkling-mini.override { inherit isWSL; cudaArchitectures = [ "86" ]; };
    ada = maya-inkling-mini.override { inherit isWSL; cudaArchitectures = [ "89" ]; };
    blackwell = maya-inkling-mini.override { inherit isWSL; cudaArchitectures = [ "120" ]; };
  };
}
