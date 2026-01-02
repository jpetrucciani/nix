# [`mods`](https://github.com/charmbracelet/mods) is a CLI tool to interact with AI APIs
{ lib
, buildGoModule
, fetchFromGitHub
, gitUpdater
, testers
, mods
}:

buildGoModule rec {
  pname = "mods";
  version = "1.8.1";

  src = fetchFromGitHub {
    owner = "charmbracelet";
    repo = "mods";
    rev = "v${version}";
    hash = "sha256-CT90uMQc0quQK/vCeLiHH8taEkCSDIcO7Q3aA+oaNmY=";
  };

  vendorHash = "sha256-Io6aNX7z6UvEAIt4qrxF0DA7/yqc8XIMG/bRVlE3nQU=";

  ldflags = [ "-s" "-w" "-X=main.version=${version}" ];

  checkPhase = ''
    runHook preCheck
    go test ./... -skip '^TestLoad$'
    runHook postCheck
  '';

  passthru = {
    updateScript = gitUpdater {
      rev-prefix = "v";
      ignoredVersions = ".(rc|beta).*";
    };

    tests.version = testers.testVersion {
      package = mods;
      command = "HOME=$(mktemp -d) mods -v";
    };
  };

  meta = with lib; {
    description = "AI on the command line";
    homepage = "https://github.com/charmbracelet/mods";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
