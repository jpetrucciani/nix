# [ahab](https://github.com/jpetrucciani/ahab) is a tool that allows you to tail one or more docker containers
{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "ahab";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "jpetrucciani";
    repo = "ahab";
    rev = version;
    hash = "sha256-epfJEx4i/yQVGOT+7wKAn7PMZpBEhUljUe51T/A4+os=";
  };

  vendorHash = "sha256-cZ/4pfreCwKv8SQ51xLOT8aGKXPN13Zh7Fq6qcdRPb0=";

  ldflags = [ "-s" "-w" "-X main.version=${version}" ];

  meta = with lib; {
    description = "Tail one or more docker container log streams";
    homepage = "https://github.com/jpetrucciani/ahab";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "ahab";
  };
}
