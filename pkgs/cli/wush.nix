# [wush](https://github.com/coder/wush) is a fast way to transfer files between computers with wireguard
{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "wush";
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "coder";
    repo = "wush";
    rev = "v${version}";
    hash = "sha256-r6LKEL9GxyiyQgM4AuLU/FcmYKOCg7EZDmAZQznCx8E=";
  };

  vendorHash = "sha256-e1XcoiJ55UoSNFUto6QM8HrQkkrBf8sv4L9J+7Lnu2I=";

  ldflags = [
    "-s"
    "-w"
    "-X=main.version=${version}"
    "-X=main.commit=${src.rev}"
    "-X=main.commitDate=0"
  ];

  meta = {
    description = "Simplest & fastest way to transfer files between computers via wireguard";
    homepage = "https://github.com/coder/wush/releases/tag/v0.1.2";
    license = lib.licenses.cc0;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "wush";
  };
}
