# [hermes-agent](https://github.com/NousResearch/hermes-agent) is a self-improving AI agent CLI
{ stdenv
, lib
, fetchFromGitHub
, python313
, rsync
, makeWrapper
, ffmpeg
, git
, libopus
, nodejs_22
, ripgrep
, uv-nix
}:
let
  name = "hermes-agent";
  version = "2026.3.30";

  src = fetchFromGitHub {
    owner = "NousResearch";
    repo = name;
    rev = "refs/tags/v${version}";
    hash = "sha256-ipfIXPikYDpJC+Hjxh2soo20WXw1i09p8pQVCtpfVMg=";
    fetchSubmodules = true;
  };

  uvEnv = uv-nix.mkEnv {
    inherit name;
    python = python313;
    workspaceRoot = src;
    pyprojectOverrides =
      final: prev:
      let
        addBuildInputs = buildInputs: pkg: pkg.overrideAttrs (old: {
          buildInputs = (old.buildInputs or [ ]) ++ buildInputs;
        });
        hatchBuildInputs = [
          final.hatchling
          final.packaging
          final.pathspec
          final.pluggy
          final."trove-classifiers"
        ];
      in
      {
        atomicwrites = addBuildInputs [ final.setuptools ] prev.atomicwrites;
        atroposlib = addBuildInputs hatchBuildInputs prev.atroposlib;
        "python-olm" = addBuildInputs [ final.setuptools ] prev."python-olm";
        tinker = addBuildInputs
          (hatchBuildInputs ++ [
            final."hatch-fancy-pypi-readme"
          ])
          prev.tinker;
        "yc-bench" = addBuildInputs hatchBuildInputs prev."yc-bench";
      };
  };

  hermesPackageDirs = [
    "acp_adapter"
    "agent"
    "cron"
    "gateway"
    "hermes_cli"
    "honcho_integration"
    "tools"
  ];

  hermesModules = [
    "batch_runner.py"
    "cli.py"
    "hermes_constants.py"
    "hermes_state.py"
    "hermes_time.py"
    "mini_swe_runner.py"
    "model_tools.py"
    "rl_cli.py"
    "run_agent.py"
    "toolset_distributions.py"
    "toolsets.py"
    "trajectory_compressor.py"
    "utils.py"
  ];

  site = python313.sitePackages;
  inherit (python313.pkgs) pynacl;
  opusLibPath = "${lib.getLib libopus}/lib/libopus${stdenv.hostPlatform.extensions.sharedLibrary}.0";

  runtimePath = lib.makeBinPath [
    ffmpeg
    git
    nodejs_22
    ripgrep
  ];
  runtimeLibraryPath = lib.makeLibraryPath [ libopus ];
in
stdenv.mkDerivation {
  inherit version src;
  pname = name;

  nativeBuildInputs = [
    makeWrapper
    rsync
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    ${rsync}/bin/rsync -a --exclude='bin/' ${uvEnv}/ $out
    find $out/${site} -type d -exec chmod u+w '{}' +

    for packageDir in ${lib.escapeShellArgs hermesPackageDirs}; do
      rm -rf "$out/${site}/$packageDir"
      cp -r "${src}/$packageDir" "$out/${site}/$packageDir"
      find "$out/${site}/$packageDir" -type d -exec chmod u+w '{}' +
    done

    for module in ${lib.escapeShellArgs hermesModules}; do
      rm -f "$out/${site}/$module"
      install -Dm644 "${src}/$module" "$out/${site}/$module"
    done

    chmod u+w $out/${site}/tools/terminal_tool.py
    chmod u+w $out/${site}/gateway/platforms/discord.py
    substituteInPlace $out/${site}/gateway/platforms/discord.py \
      --replace-fail \
      '            opus_path = ctypes.util.find_library("opus")' \
      '            opus_path = os.environ.get("HERMES_OPUS_LIBRARY") or ctypes.util.find_library("opus")'
    cp ${uvEnv}/bin/hermes $out/bin/hermes
    cp ${uvEnv}/bin/hermes-agent $out/bin/hermes-agent
    wrapProgram $out/bin/hermes \
      --prefix PATH : ${runtimePath} \
      --prefix LD_LIBRARY_PATH : ${runtimeLibraryPath} \
      --set-default HERMES_OPUS_LIBRARY ${opusLibPath} \
      --prefix PYTHONPATH : ${pynacl}/${site} \
      --prefix PYTHONPATH : $out/${site}
    wrapProgram $out/bin/hermes-agent \
      --prefix PATH : ${runtimePath} \
      --prefix LD_LIBRARY_PATH : ${runtimeLibraryPath} \
      --set-default HERMES_OPUS_LIBRARY ${opusLibPath} \
      --prefix PYTHONPATH : ${pynacl}/${site} \
      --prefix PYTHONPATH : $out/${site}
    runHook postInstall
  '';

  meta = {
    changelog = "https://github.com/NousResearch/hermes-agent/releases/tag/v${version}";
    description = "A self-improving AI agent CLI";
    homepage = "https://github.com/NousResearch/hermes-agent";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "hermes";
  };
}
