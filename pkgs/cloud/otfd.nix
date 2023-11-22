{ lib
, buildGoModule
, fetchFromGitHub
}:
buildGoModule rec {
  pname = "otfd";
  version = "0.1.18";

  src = fetchFromGitHub {
    owner = "jpetrucciani";
    repo = "otf";
    rev = "d988a1f0da0b4baeb57f3d0628dbdac285646b8b";
    hash = "sha256-nn6RDTAb2TOl4Rn4bM9T2btGjhVxwb6nSNZCVjVk9ZU=";
  };

  vendorHash = "sha256-bgZVCwWTpLhW1pOaGe/M28SdCadj/pNoSRlx2CRxxRU=";

  doCheck = false;

  ldflags = [
    "-s"
    "-w"
    "-X=github.com/leg100/otf/internal.Version=${version}"
    "-X=github.com/leg100/otf/internal.Commit=${src.rev}"
    "-X=github.com/leg100/otf/internal.Built=1970-01-01T00:00:00Z"
  ];

  meta = with lib; {
    description = "An open source alternative to terraform enterprise";
    homepage = "https://github.com/leg100/otf";
    changelog = "https://github.com/leg100/otf/blob/${src.rev}/CHANGELOG.md";
    license = licenses.mpl20;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "otfd";
  };
}
