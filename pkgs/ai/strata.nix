# [Strata](https://github.com/Niko1221/Strata) runs Qwen Flash-Next and Inkling 2 Mini with CUDA.
{ strata
, lib
, hax
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
  version = "0.2.19";
  engineVersion = "0.1.65";
  src = fetchFromGitHub {
    owner = "Niko1221";
    repo = "Strata";
    rev = "c6f6427d9de9016fd92d13e29740f65625261df7";
    hash = "sha256-hoqWE28i0b1R1+//WJMqk1wYmvfh2uNHd4yiL9U66RA=";
  };
  cudaPackages = cudaPackages_13_0;
  driverPath = hax.cudaDriverPath { inherit isWSL; };
  driverWrapperArgs = lib.escapeShellArgs (lib.optionals isWSL (hax.wslCudaWrapperArgs { includeDriverTools = true; }));
  meta = {
    description = "CUDA inference for Qwen Flash-Next and Inkling 2 Mini";
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
  # Driver selection only changes the wrappers, so native Linux and WSL share this build.
  engine = cudaPackages.backendStdenv.mkDerivation {
    pname = "strata-engine";
    version = engineVersion;
    inherit src;

    strictDeps = true;
    nativeBuildInputs = [ cmake ninja autoAddDriverRunpath cudaPackages.cuda_nvcc ];
    buildInputs = with cudaPackages; [ cuda_cudart cccl libcublas ];

    cmakeDir = "../engine";
    cmakeFlags = [
      (lib.cmakeBool "STRATA_ENABLE_CUDA" true)
      (lib.cmakeBool "STRATA_PORTABLE" true)
      (lib.cmakeBool "STRATA_BUILD_TESTS" false)
      (lib.cmakeFeature "CMAKE_CUDA_ARCHITECTURES" (lib.concatStringsSep ";" cudaArchitectures))
    ];
    ninjaFlags = [ "strata" "strata-inkling" ];

    installPhase = ''
      runHook preInstall

      install -Dm755 strata "$out/libexec/strata/strata"
      install -Dm755 src/inkling2/strata-inkling "$out/libexec/strata/strata-inkling"
      mkdir -p "$out/bin"
      ln -s ../libexec/strata/strata "$out/bin/strata-engine"

      runHook postInstall
    '';

    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck

      # These commands do no GPU work. The sandbox has no host NVIDIA driver.
      export LD_LIBRARY_PATH="${cudaPackages.cuda_cudart}/lib/stubs"
      "$out/libexec/strata/strata" --help >/dev/null 2>&1
      test "$("$out/libexec/strata/strata-inkling" --version)" = "strata-inkling ${engineVersion}"

      runHook postInstallCheck
    '';

    meta = meta // { mainProgram = "strata-engine"; };
  };
  engineDir = "${engine}/libexec/strata";
in
stdenvNoCC.mkDerivation {
  pname = "strata";
  inherit version src meta;

  strictDeps = true;
  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  postPatch = ''
    # Model preparation uses the packaged engines and keeps verification state outside the store.
    substituteInPlace terminal/setup.py \
      --replace-fail 'return ROOT / "marks" /' 'return home() / "marks" /' \
      --replace-fail 'return "component:strata-engine" if CONTROL else str(eng / EXE)' \
        'return "${engineDir}/strata" if CONTROL else str(eng / EXE)' \
      --replace-fail 'return shape_engine.reference(SHAPE_ENGINE["shape"])' \
        'return str(eng / inkling_family.EXE) if CONTROL and SHAPE_ENGINE["shape"] == inkling_family.SHAPE else shape_engine.reference(SHAPE_ENGINE["shape"])' \
      --replace-fail 'return shape_engine_step(a, gpu, vision)' \
        'if CONTROL and SHAPE_ENGINE["shape"] == inkling_family.SHAPE:
                return llama_cpp_if_here(), Path("${engineDir}"), {"version": "${engineVersion}", "source": "local"}, ["${driverPath}"], gpu, "none"
            return shape_engine_step(a, gpu, vision)' \
      --replace-fail 'return control_engine_step(gpu, vision)' \
        'return llama_cpp_if_here(), Path("${engineDir}"), {"version": "${engineVersion}", "source": "local"}, ["${driverPath}"], gpu, "none"'
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/strata/third_party"
    cp -r terminal/{strata.py,strata_cli,strata_control,serve,tools,ref,data,bench,setup.py} docs "$out/share/strata/"
    cp -r engine/third_party/strata-gguf-py "$out/share/strata/third_party/"
    printf '%s\n' '${version}' > "$out/share/strata/VERSION"

    makeWrapper ${lib.getExe python} "$out/bin/strata" \
      ${driverWrapperArgs} \
      --add-flags "-B $out/share/strata/strata.py" \
      --set STRATA_NO_HANDOVER 1
    makeWrapper "${engineDir}/strata" "$out/bin/strata-engine" ${driverWrapperArgs}
    makeWrapper "${engineDir}/strata-inkling" "$out/bin/strata-inkling" ${driverWrapperArgs}
    makeWrapper ${lib.getExe python} "$out/bin/strata-prepare" \
      ${driverWrapperArgs} \
      --add-flags "-B $out/share/strata/setup.py --no-start --vision no" \
      --set STRATA_CONTROL_INSTALL 1 \
      --set-default STRATA_INSTALL_DIR .

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

    setup.SHAPE_ENGINE["shape"] = setup.inkling_family.SHAPE
    _, engine, _, driver_dirs, _, _ = setup.engine_step(None, {}, False, None, None, "none")
    exe = Path(setup.engine_exe(engine))
    assert exe == Path("${engineDir}/strata-inkling") and exe.is_file()
    assert driver_dirs == ["${driverPath}"]

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
