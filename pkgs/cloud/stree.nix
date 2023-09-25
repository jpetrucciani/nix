{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "stree";
  version = "0.0.10";

  src = fetchFromGitHub {
    owner = "orangekame3";
    repo = "stree";
    rev = "v${version}";
    hash = "sha256-Emq2klhSxf6Gd2MYkrLR7AcQcPlWgkv/VV7W2den8cM=";
  };

  vendorHash = "sha256-Hf2ovkt0pBW4fILIVmRh6I8Q2loE+BoA26SBH7wicz0=";

  ldflags = [ "-s" "-w" ];

  meta = with lib; {
    description = "Directory trees of S3";
    homepage = "https://github.com/orangekame3/stree";
    changelog = "https://github.com/orangekame3/stree/blob/${src.rev}/CHANGELOG.md";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
