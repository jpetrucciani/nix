# [hermes-agent](https://github.com/NousResearch/hermes-agent) is a self-improving AI agent CLI
{ stdenv
, lib
, fetchFromGitHub
, python313
, rsync
, makeWrapper
, ffmpeg
, git
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

  site = python313.sitePackages;

  runtimePath = lib.makeBinPath [
    ffmpeg
    git
    nodejs_22
    ripgrep
  ];
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

    rm $out/${site}/tools
    cp -r ${src}/tools $out/${site}/tools

    rm $out/${site}/mini_swe_runner.py
    install -Dm644 ${src}/mini_swe_runner.py $out/${site}/mini_swe_runner.py

    rm $out/${site}/hermes_cli
    cp -r ${src}/hermes_cli $out/${site}/hermes_cli

    cp -r ${src}/mini-swe-agent/src/minisweagent $out/${site}/minisweagent
    chmod u+w $out/${site}/tools
    chmod u+w $out/${site}/hermes_cli
    chmod u+w $out/${site}/tools/terminal_tool.py
    chmod u+w $out/${site}/mini_swe_runner.py
    chmod u+w $out/${site}/hermes_cli/doctor.py
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
    cp ${uvEnv}/bin/hermes $out/bin/hermes
    cp ${uvEnv}/bin/hermes-agent $out/bin/hermes-agent
    wrapProgram $out/bin/hermes \
      --prefix PATH : ${runtimePath} \
      --prefix PYTHONPATH : $out/${site}
    wrapProgram $out/bin/hermes-agent \
      --prefix PATH : ${runtimePath} \
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
