# [Strata](https://github.com/Niko1221/Strata) runs Qwen Flash-Next with CPU and CUDA expert caching.
{ strata
, lib
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
  version = "0.1.59.1";
  src = fetchFromGitHub {
    owner = "Niko1221";
    repo = "Strata";
    rev = "13eedf552417a6a791a7d13c6597e24300ee3a09";
    hash = "sha256-50Z0ks2k6f+UsSJwOq528l4eIUnh+12/PH/KU+5sR0Y=";
  };
  cudaPackages = cudaPackages_13_0;
  driverPath = if isWSL then "/usr/lib/wsl/lib" else "/run/opengl-driver/lib";
  driverWrapperArgs = lib.escapeShellArgs (lib.optionals isWSL [
    "--prefix"
    "LD_LIBRARY_PATH"
    ":"
    driverPath
    "--prefix"
    "PATH"
    ":"
    "/usr/lib/wsl/lib"
  ]);
  meta = {
    description = "Qwen Flash-Next inference with CPU and CUDA expert caching";
    homepage = "https://github.com/Niko1221/Strata";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "strata";
    platforms = [ "x86_64-linux" ];
    skipBuild = true; # CUDA builds stay out of the aggregate CI build.
  };
  python = python312.withPackages (ps: with ps; [
    jinja2
    numpy
    pillow
    psutil
    pyyaml
    regex
    requests
    tqdm
    truststore
  ]);
  llamaSource = fetchFromGitHub {
    owner = "ggml-org";
    repo = "llama.cpp";
    rev = "3cf03257f219afbe7334045ff7c6a06ac68c627d";
    hash = "sha256-SRGoXa+4ACBCB3eaG9XFYhMN1i0FyPEy9Rrer+dFGYI=";
  };
  # Driver selection only changes the wrappers, so native Linux and WSL share this build.
  engine = cudaPackages.backendStdenv.mkDerivation {
    pname = "strata-engine";
    inherit version src;

    strictDeps = true;
    nativeBuildInputs = [ cmake ninja autoAddDriverRunpath cudaPackages.cuda_nvcc ];
    buildInputs = with cudaPackages; [ cuda_cudart cccl libcublas ];

    cmakeFlags = [
      (lib.cmakeBool "STRATA_ENABLE_CUDA" true)
      (lib.cmakeBool "STRATA_PORTABLE" true)
      (lib.cmakeBool "STRATA_BUILD_TESTS" false)
      (lib.cmakeFeature "CMAKE_CUDA_ARCHITECTURES" (lib.concatStringsSep ";" cudaArchitectures))
    ];
    ninjaFlags = [ "strata" "strata_kq" ];

    installPhase = ''
      runHook preInstall

      # K-quant kernels are loaded relative to /proc/self/exe, so keep them beside the real binary.
      install -Dm755 strata "$out/libexec/strata/strata"
      install -Dm755 libstrata_kq.so "$out/libexec/strata/libstrata_kq.so"
      mkdir -p "$out/bin"
      ln -s ../libexec/strata/strata "$out/bin/strata-engine"

      runHook postInstall
    '';

    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck

      # Help does no GPU work; the build sandbox has no host NVIDIA driver.
      LD_LIBRARY_PATH="${cudaPackages.cuda_cudart}/lib/stubs" "$out/libexec/strata/strata" --help >/dev/null 2>&1

      runHook postInstallCheck
    '';

    meta = meta // { mainProgram = "strata-engine"; };
  };
in
stdenvNoCC.mkDerivation {
  pname = "strata";
  inherit version src meta;

  strictDeps = true;
  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  postPatch = ''
    # Model preparation uses the Nix engine and gguf-py, without acquiring another toolchain or engine.
    substituteInPlace setup.py \
      --replace-fail 'llama = home() / "third_party" / "llama.cpp"' 'llama = Path("${llamaSource}")' \
      --replace-fail 'return ROOT / "marks" /' 'return home() / "marks" /' \
      --replace-fail 'return "component:strata-engine" if CONTROL else str(eng / EXE)' \
        'return "${engine}/libexec/strata/strata" if CONTROL else str(eng / EXE)' \
      --replace-fail 'return control_engine_step(gpu, vision)' \
        'return llama_cpp_if_here(), Path("${engine}/libexec/strata"), {"version": "${version}", "source": "local"}, ["${driverPath}"], gpu, "none"'
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/strata"
    cp -r strata.py strata_cli strata_control serve tools ref data bench docs setup.py "$out/share/strata/"
    printf '%s\n' '${version}' > "$out/share/strata/VERSION"

    makeWrapper ${lib.getExe python} "$out/bin/strata" \
      ${driverWrapperArgs} \
      --add-flags "-B $out/share/strata/strata.py" \
      --set STRATA_NO_HANDOVER 1 \
      --set STRATA_GGUF_PY "${llamaSource}/gguf-py"
    makeWrapper "${engine}/libexec/strata/strata" "$out/bin/strata-engine" ${driverWrapperArgs}
    makeWrapper ${lib.getExe python} "$out/bin/strata-prepare" \
      ${driverWrapperArgs} \
      --add-flags "-B $out/share/strata/setup.py --no-start --vision no" \
      --set STRATA_CONTROL_INSTALL 1 \
      --set-default STRATA_INSTALL_DIR . \
      --set STRATA_GGUF_PY "${llamaSource}/gguf-py"

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    "$out/bin/strata" --version
    "$out/bin/strata" --help >/dev/null
    "$out/bin/strata" serve --help >/dev/null
    ${lib.getExe python} -B "$out/share/strata/serve/server.py" --help >/dev/null
    "$out/bin/strata-prepare" --help >/dev/null

    STRATA_CONTROL_INSTALL=1 STRATA_INSTALL_DIR="$TMPDIR/strata-install" \
      ${lib.getExe python} -B - "$out/share/strata" <<'PY'
    import sys
    import tempfile
    from pathlib import Path

    sys.path.insert(0, sys.argv[1])
    import setup

    with tempfile.TemporaryDirectory() as directory:
        model = Path(directory) / "model.gguf"
        model.write_bytes(b"fixture")
        setup.own_files_in(directory)
        setup.mark(model, "verified")
        assert setup.done(model), "verification marks must survive outside the read-only package"
        assert (setup.home() / "marks").is_dir(), "keep verification state in STRATA_INSTALL_DIR"
        assert not model.with_name("model.gguf.done").exists(), "leave user-owned model files alone"
    PY

    runHook postInstallCheck
  '';

  passthru = {
    inherit engine cudaArchitectures;
    wsl = strata.override { inherit cudaArchitectures; isWSL = true; };
    ampere = strata.override { inherit isWSL; cudaArchitectures = [ "86" ]; };
    ada = strata.override { inherit isWSL; cudaArchitectures = [ "89" ]; };
    blackwell = strata.override { inherit isWSL; cudaArchitectures = [ "120" ]; };
  };
}
