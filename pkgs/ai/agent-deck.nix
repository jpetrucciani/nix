# [agent-deck](https://github.com/asheshgoplani/agent-deck) is a terminal session manager for AI coding agents. One TUI for Claude, Gemini, OpenCode, Codex, and more
{ lib
, buildGoLatestModule
, fetchFromGitHub
, git
, python3
, mkPyWrapped
}:
buildGoLatestModule (finalAttrs: {
  pname = "agent-deck";
  version = "1.5.0";

  src = fetchFromGitHub {
    owner = "asheshgoplani";
    repo = "agent-deck";
    tag = "v${finalAttrs.version}";
    hash = "sha256-0jOgTHlF2vx4fQC0V0sUyHAmi3YgNP3wydKiXp5pr9M=";
  };

  vendorHash = "sha256-xGf1KrSc0Jl75FqFjt5KJslQeVRQPFljqTxF7MphhNk=";

  nativeCheckInputs = [
    git
    python3
  ];

  preCheck = ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
  '';

  checkFlags = [ "-skip=TestSmoke_BuildVersion" ];

  ldflags = [
    "-s"
    "-w"
    "-X=main.Version=${finalAttrs.version}"
  ];

  passthru = {
    agent-deck-conductor-python-discord = mkPyWrapped { pname = "agent-deck-conductor-python-discord"; withPackages = (p: with p; [ toml discordpy ]); };
  };

  meta = {
    description = "Terminal session manager for AI coding agents. One TUI for Claude, Gemini, OpenCode, Codex, and more";
    homepage = "https://github.com/asheshgoplani/agent-deck";
    changelog = "https://github.com/asheshgoplani/agent-deck/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "agent-deck";
  };
})
