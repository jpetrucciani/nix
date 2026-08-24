# [stree](https://github.com/orangekame3/stree) is a directory tree tool for s3
{ lib
, buildGoModule
, fetchFromGitHub
, nix-update-script
}:

buildGoModule rec {
  pname = "stree";
  version = "0.0.21";

  src = fetchFromGitHub {
    owner = "orangekame3";
    repo = "stree";
    rev = "v${version}";
    hash = "sha256-DqWy+ZZDsqoU6uAqSEhXyTlPExAuJUUs2NnhWxRva+Y=";
  };

  vendorHash = "sha256-U31p34cr/6vfnffjs12Y5cBeljonm16BQyewyyx3iuQ=";

  patches = [ ./stree-version.patch ];

  ldflags = [ "-s" "-w" ];

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Directory trees of S3";
    homepage = "https://github.com/orangekame3/stree";
    changelog = "https://github.com/orangekame3/stree/blob/${src.rev}/CHANGELOG.md";
    license = licenses.mit;
    mainProgram = "stree";
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
