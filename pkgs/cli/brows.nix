# [brows](https://github.com/rubysolo/brows) is a CLI tool to browse github releases
{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "brows";
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "rubysolo";
    repo = "brows";
    rev = "v${version}";
    hash = "sha256-l2rynzzZofG2JI+SsHqcbSEnMe63u+vdO2Leoe/IAZY=";
  };

  vendorHash = "sha256-m6kNEWr41BQd4TdsYWXWBaTJCxLBHQL6xVaThUOcCKM=";

  ldflags = [ "-s" "-w" ];

  meta = with lib; {
    description = "CLI GitHub release browser";
    homepage = "https://github.com/rubysolo/brows";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "brows";
  };
}
