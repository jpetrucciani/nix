{ lib
, buildGoModule
, fetchFromGitHub
}:
buildGoModule rec {
  pname = "otfd";
  version = "0.2.4";

  src = fetchFromGitHub {
    owner = "leg100";
    repo = "otf";
    rev = "refs/tags/v${version}";
    hash = "sha256-GlqtrCKDAnIU1KUWjYq22u7V8XLZeUQPEVLKAKx9tog=";
  };

  vendorHash = "sha256-+5Y2sZJEo3s9WfzJOACsjnH3sCtmCoqTkr2+i1hyR6Y=";

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
