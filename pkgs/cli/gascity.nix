{ lib
, bash
, beads
, buildGo126Module
, coreutils
, docker-client
, dolt
, fetchFromGitHub
, findutils
, flock
, gawk
, gh
, git
, gnugrep
, gnused
, jq
, kubectl
, lsof
, makeWrapper
, netcat
, openssh
, procps
, python3
, sqlite
, stdenv
, tmux
, util-linux
}:
let
  commit = "58ef17e3bd685fd5cf7f21286277b208d3324590";
  # Gas City compares the external bd binary with its linked Beads library version.
  beadsForGascity = beads.overrideAttrs (finalAttrs: _: {
    version = "1.2.2";

    src = fetchFromGitHub {
      owner = "gastownhall";
      repo = "beads";
      tag = "v${finalAttrs.version}";
      hash = "sha256-HSZ1z4WaHQDPomW6nNs8iUnld36BuHnOVaODD5mxY00=";
    };

    vendorHash = "sha256-WWEwGpCwMPD7jaz02zN745RQQqYTQttehbcT3J9hayM=";

    checkFlags =
      let
        skippedTests = [
          # Git executes a generated #!/usr/bin/env hook, but /usr/bin/env is absent in the Nix sandbox.
          "TestInstallHooksBeads_WorktreeAccess"
        ]
        ++ lib.optionals stdenv.hostPlatform.isDarwin [
          "TestCleanupMergeArtifacts_CommandInjectionPrevention"
        ];
      in
      [ "-skip=^(${lib.concatStringsSep "|" skippedTests})$" ];
  });
  # Configured agent CLIs, herdr, host service managers, and daemons remain user-supplied.
  runtimeDependencies = [
    bash
    beadsForGascity
    coreutils
    docker-client
    dolt
    findutils
    flock
    gawk
    gh
    git
    gnugrep
    gnused
    jq
    kubectl
    lsof
    netcat
    openssh
    procps
    python3
    sqlite
    tmux
    util-linux
  ];
  runtimePath = lib.makeBinPath runtimeDependencies;
in
buildGo126Module (finalAttrs: {
  pname = "gascity";
  version = "1.4.1";

  src = fetchFromGitHub {
    owner = "gastownhall";
    repo = "gascity";
    rev = "refs/tags/v${finalAttrs.version}";
    hash = "sha256-QhK62+uuippG4xEg3mFYMeaN0Xj7Cyrfgf0NmyD+9wA=";
  };

  vendorHash = "sha256-T6e9Nq5ucWZvF1GP1/E619b2HRkBfCTNR1cF0Hx3k18=";

  subPackages = [ "cmd/gc" ];
  env.CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
    "-X=main.version=v${finalAttrs.version}"
    "-X=main.commit=${commit}"
    "-X=main.date=2026-08-15T23:17:11Z"
    "-X=github.com/gastownhall/gascity/internal/productmetrics.compiledReleaseTag=${finalAttrs.version}"
  ];

  nativeBuildInputs = [ makeWrapper ];

  postFixup = ''
    wrapProgram "$out/bin/gc" --prefix PATH : ${lib.escapeShellArg runtimePath}
  '';

  # The upstream unit target requires its environment-scrubbing harness and GC_FAST_UNIT;
  # buildGoModule's generic check phase would bypass both and enable process-backed tests.
  doCheck = false;

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    test "$("$out/bin/gc" version)" = "${finalAttrs.version}"
    for runtimeDir in ${lib.escapeShellArgs (lib.splitString ":" runtimePath)}; do
      grep -F -- "$runtimeDir" "$out/bin/gc" >/dev/null
    done

    runHook postInstallCheck
  '';

  passthru.beads = beadsForGascity;

  meta = {
    changelog = "https://github.com/gastownhall/gascity/releases/tag/v${finalAttrs.version}";
    description = "Composable orchestration infrastructure for multi-agent coding workflows";
    homepage = "https://github.com/gastownhall/gascity";
    license = lib.licenses.mit;
    mainProgram = "gc";
    maintainers = with lib.maintainers; [ jpetrucciani ];
    platforms = [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-darwin"
      "x86_64-linux"
    ];
  };
})
