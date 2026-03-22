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
  version = "2026.3.17";

  src = fetchFromGitHub {
    owner = "NousResearch";
    repo = name;
    rev = "refs/tags/v${version}";
    hash = "sha256-JGjusff/jGjvCCdUtl9IErBTGmpIq6BVA5Gj8mwqVYg=";
    fetchSubmodules = true;
  };

  uvEnv = uv-nix.mkEnv {
    inherit name;
    python = python313;
    workspaceRoot = src;
    pyprojectOverrides = final: prev: { };
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
      rm -r "$out/${site}/$packageDir"
      cp -r "${src}/$packageDir" "$out/${site}/$packageDir"
      find "$out/${site}/$packageDir" -type d -exec chmod u+w '{}' +
    done

    for module in ${lib.escapeShellArgs hermesModules}; do
      rm "$out/${site}/$module"
      install -Dm644 "${src}/$module" "$out/${site}/$module"
    done

    cp -r ${src}/mini-swe-agent/src/minisweagent $out/${site}/minisweagent
    chmod u+w $out/${site}/tools/terminal_tool.py
    chmod u+w $out/${site}/mini_swe_runner.py
    chmod u+w $out/${site}/hermes_cli/doctor.py
    chmod u+w $out/${site}/gateway/platforms/discord.py
    substituteInPlace $out/${site}/tools/terminal_tool.py \
      --replace-fail \
      'from minisweagent_path import ensure_minisweagent_on_path' \
      $'try:\n    from minisweagent_path import ensure_minisweagent_on_path\nexcept ImportError:\n    def ensure_minisweagent_on_path(_repo_root=None):\n        return None'
    substituteInPlace $out/${site}/mini_swe_runner.py \
      --replace-fail \
      'from minisweagent_path import ensure_minisweagent_on_path' \
      $'try:\n    from minisweagent_path import ensure_minisweagent_on_path\nexcept ImportError:\n    def ensure_minisweagent_on_path(_repo_root=None):\n        return None'
    substituteInPlace $out/${site}/hermes_cli/doctor.py \
      --replace-fail \
      $'    mini_swe_dir = PROJECT_ROOT / "mini-swe-agent"\n    if mini_swe_dir.exists() and (mini_swe_dir / "pyproject.toml").exists():\n        try:\n            __import__("minisweagent")\n            check_ok("mini-swe-agent", "(terminal backend)")\n        except ImportError:\n            check_warn("mini-swe-agent found but not installed", "(run: uv pip install -e ./mini-swe-agent)")\n            issues.append("Install mini-swe-agent: uv pip install -e ./mini-swe-agent")\n    else:\n        check_warn("mini-swe-agent not found", "(run: git submodule update --init --recursive)")' \
      $'    mini_swe_dir = PROJECT_ROOT / "mini-swe-agent"\n    try:\n        __import__("minisweagent")\n        check_ok("mini-swe-agent", "(terminal backend)")\n    except ImportError:\n        if mini_swe_dir.exists() and (mini_swe_dir / "pyproject.toml").exists():\n            check_warn("mini-swe-agent found but not installed", "(run: uv pip install -e ./mini-swe-agent)")\n            issues.append("Install mini-swe-agent: uv pip install -e ./mini-swe-agent")\n        else:\n            check_warn("mini-swe-agent not found", "(run: git submodule update --init --recursive)")'
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
