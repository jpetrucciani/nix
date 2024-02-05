{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "dep-tree";
  version = "0.19.3";

  src = fetchFromGitHub {
    owner = "gabotechs";
    repo = "dep-tree";
    rev = "v${version}";
    hash = "sha256-HEtqcbMd+HWE1lolLJtZbgJQuppDniPK8r6/SXTcJjE=";
  };

  vendorHash = "sha256-VtExC9pzU3lDOzmX5odyrhBZpl1qwPdDEz9axdQCx4I=";

  ldflags = [ "-s" "-w" ];
  doCheck = false;

  meta = with lib; {
    description = "Tool for helping developers keep their code bases clean and decoupled. It allows visualising a \"code base entropy\" using a 3d force-directed graph of files and the dependencies between";
    homepage = "https://github.com/gabotechs/dep-tree";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "dep-tree";
  };
}
