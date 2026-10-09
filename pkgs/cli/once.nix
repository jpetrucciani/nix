{ lib
, buildGo127Module
, fetchFromGitHub
}:

buildGo127Module (finalAttrs: {
  pname = "once";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "alex0ptr";
    repo = "once";
    tag = "v${finalAttrs.version}";
    hash = "sha256-CIDu3UJoJd/Jmqo8gHEI0FxlUu+l1z6xvjbilD2/+q0=";
  };

  vendorHash = null;
  env.CGO_ENABLED = 0;
  ldflags = [ "-s" "-w" ];

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/once" --help
    runHook postInstallCheck
  '';

  meta = {
    description = "Cache command output in memory with a per-user background daemon";
    homepage = "https://github.com/alex0ptr/once";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.jpetrucciani ];
    mainProgram = "once";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
