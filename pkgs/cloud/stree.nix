# [stree](https://github.com/orangekame3/stree) is a directory tree tool for s3
{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "stree";
  version = "0.0.12";

  src = fetchFromGitHub {
    owner = "orangekame3";
    repo = "stree";
    rev = "v${version}";
    hash = "sha256-qqzdonQXrFFu/jvgwhaBL/gDEtjM9DFhn138SAAHwaY=";
  };

  vendorHash = "sha256-H1WPIYw9KXDd8Z1/gRi3hCfe63RdMMBh26hhLfnniqk=";

  ldflags = [ "-s" "-w" ];

  meta = with lib; {
    description = "Directory trees of S3";
    homepage = "https://github.com/orangekame3/stree";
    changelog = "https://github.com/orangekame3/stree/blob/${src.rev}/CHANGELOG.md";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
