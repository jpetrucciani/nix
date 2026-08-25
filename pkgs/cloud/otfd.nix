# [otfd](https://github.com/jpetrucciani/otf) is an open source terraform cloud
{ lib
, buildGoModule
, fetchFromGitHub
, stdenv
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

  postPatch = ''
    patchShebangs internal/agent/testdata
    substituteInPlace internal/run/cli_test.go \
      --replace-fail 'assert.Regexp(t, `Extracted tarball to: /tmp/run-123-.*`, got.String())' \
      'assert.Regexp(t, `Extracted tarball to: `+os.TempDir()+`/run-123-.*`, got.String())'

    ${lib.optionalString stdenv.hostPlatform.isDarwin ''
      # The downloader test selects its fixture using runtime.GOOS/runtime.GOARCH,
      # but upstream only provides Linux archives containing the shared fake binary.
      cp \
        internal/releases/testdata/releases/terraform/1.2.3/terraform_1.2.3_linux_${stdenv.hostPlatform.go.GOARCH}.zip \
        internal/releases/testdata/releases/terraform/1.2.3/terraform_1.2.3_darwin_${stdenv.hostPlatform.go.GOARCH}.zip
    ''}
  '';

  # This package starts databases, daemons, browsers, and external providers.
  excludedPackages = [ "internal/integration" ];
  checkFlags = [ "-timeout=30s" ];

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
