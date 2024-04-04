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
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "charmbracelet";
    repo = "mods";
    rev = "v${version}";
    hash = "sha256-0PykG19DAVVziRAefQ0LENMuTfTJSVFvs0bMJXdDkrE=";
  };

  vendorHash = "sha256-DfIXW5cfTnXPgl9IC5+wTFJ04qWX4RlVoDIYM5gooks=";

  ldflags = [ "-s" "-w" "-X=main.version=${version}" ];

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
    maintainers = with maintainers; [ ];
  };
}
