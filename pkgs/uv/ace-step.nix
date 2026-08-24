# [ACE-Step](https://github.com/ace-step/ACE-Step-1.5) is an open-source music generation model and serving API.
{ ace-step
, lib
, stdenv
, uv-nix
, python311
, rsync
, makeWrapper
, bash
, clang
, ninja
, ffmpeg
, openssl
, cudaPackages_12_8
, nix-update-script
, version ? "0.1.8"
, srcHash ? "sha256-5lqS6OMI6IwFRm0mO+4EVKGYrO4QcEgL4QAFQy5bvAU="
, isWSL ? false
}:
let
  cudaToolkit = cudaPackages_12_8.cudatoolkit;
  ldPath = if isWSL then "/usr/lib/wsl/lib" else "/run/opengl-driver/lib";
  src = uv-nix.fetchGitHubWorkspace {
    owner = "ace-step";
    repo = "ACE-Step-1.5";
    rev = "refs/tags/v${version}";
    hash = srcHash;
  };
  uvEnv = uv-nix.mkEnv {
    name = "ace-step";
    gitignore = false;
    python = python311;
    workspaceRoot = src;
    enableCuda = true;
    pyprojectOverrides = _final: prev: {
      "ace-step" = prev."ace-step".overrideAttrs (old: {
        # Installed Python packages live in the immutable Nix store. ACE-Step
        # otherwise creates gradio_outputs beside its modules during import.
        postInstall = (old.postInstall or "") + ''
          patch \
            --fuzz=0 \
            -d "$out/${python311.sitePackages}" \
            -p1 \
            < ${./patches/ace-step-writable-project-root.patch}
        '';
      });
      calver = prev.calver.overrideAttrs (old: {
        # ACE-Step intentionally pins its runtime setuptools below 72, while
        # calver uses PEP 639 license metadata and requires setuptools 77 or
        # newer to build. Keep the runtime pin and replace only this package's
        # build backend.
        nativeBuildInputs = builtins.filter
          (input: (input.pname or "") != "setuptools")
          (old.nativeBuildInputs or [ ]);
        NIX_PYPROJECT_PYTHONPATH = "${python311.pkgs.setuptools}/${python311.sitePackages}";
      });
    };
  };
  programs = [
    "acestep"
    "acestep-api"
    "acestep-download"
    "acestep-openrouter"
  ];
  runtimePath = lib.makeBinPath [
    bash
    clang
    cudaToolkit
    ffmpeg
    ninja
    openssl
  ];
in
stdenv.mkDerivation {
  pname = "ace-step";
  inherit version src;

  nativeBuildInputs = [
    makeWrapper
    rsync
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    ${rsync}/bin/rsync -a --exclude='bin/' ${uvEnv}/ $out

    sitePackages=$(echo "$out"/lib/python*/site-packages)
    wheelCudaLibs="$sitePackages/torch/lib"
    for libdir in "$sitePackages"/nvidia/*/lib; do
      wheelCudaLibs="$wheelCudaLibs:$libdir"
    done

    for program in ${lib.escapeShellArgs programs}; do
      cp "${uvEnv}/bin/$program" "$out/bin/$program"
      wrapProgram "$out/bin/$program" \
        --set PYTHONNOUSERSITE 1 \
        --set LD_LIBRARY_PATH "$wheelCudaLibs:${ldPath}" \
        --set CUDA_HOME "${cudaToolkit}" \
        --set CUDA_PATH "${cudaToolkit}" \
        --prefix CPATH : "${cudaToolkit}/include" \
        --prefix CPLUS_INCLUDE_PATH : "${cudaToolkit}/include" \
        --prefix LIBRARY_PATH : "${cudaToolkit}/lib" \
        --prefix LIBRARY_PATH : "${ldPath}" \
        --set TRITON_LIBCUDA_PATH "${ldPath}" \
        --set TRITON_PTXAS_PATH "${cudaToolkit}/bin/ptxas" \
        --prefix PATH : "${runtimePath}"
    done
    runHook postInstall
  '';

  passthru = {
    inherit src;
    updateScript = nix-update-script { };
    wsl = ace-step.override {
      inherit version srcHash;
      isWSL = true;
    };
  };

  meta = {
    changelog = "https://github.com/ace-step/ACE-Step-1.5/releases/tag/v${version}";
    description = "Open-source music generation model and serving API";
    homepage = "https://github.com/ace-step/ACE-Step-1.5";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "acestep-api";
    platforms = [ "x86_64-linux" ];
    skipBuild = true; # don't ever build this on github actions - it's quite heavy!
  };
}
