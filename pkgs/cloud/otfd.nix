# [otfd](https://github.com/jpetrucciani/otf) is an open source terraform cloud
{ lib
, buildGoModule
, fetchFromGitHub
}:
buildGoModule rec {
  pname = "otfd";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "jpetrucciani";
    repo = "otf";
    rev = "refs/tags/v${version}";
    hash = "sha256-WE58boMncByrJIZiqxQxF1SIBiarLMKKKcnzCvVxY8Y=";
  };

  vendorHash = "sha256-+5Y2sZJEo3s9WfzJOACsjnH3sCtmCoqTkr2+i1hyR6Y=";

  doCheck = false;

  ldflags = [
    "-s"
    "-w"
    "-X=github.com/jpetrucciani/otf/internal.Version=${version}"
    "-X=github.com/jpetrucciani/otf/internal.Commit=${src.rev}"
    "-X=github.com/jpetrucciani/otf/internal.Built=1970-01-01T00:00:00Z"
  ];

  meta = with lib; {
    description = "An open source alternative to terraform enterprise";
    homepage = "https://github.com/jpetrucciani/otf";
    changelog = "https://github.com/jpetrucciani/otf/blob/${src.rev}/CHANGELOG.md";
    license = licenses.mpl20;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "otfd";
  };
}
