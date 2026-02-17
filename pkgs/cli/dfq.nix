{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, installShellFiles
}:

rustPlatform.buildRustPackage rec {
  pname = "dfq";
  version = "0.0.2";

  src = fetchFromGitHub {
    owner = "jpetrucciani";
    repo = "dfq";
    rev = "v${version}";
    hash = "sha256-rnyYmQz4i7ETcEaejrbAUvDFgHU72bUgDH9FWraFMm4=";
  };

  cargoHash = "sha256-rKk5u0PIfxqWs2xMIyCq3H1PiM2ny+EbT/HhxXQq2tY=";

  nativeBuildInputs = [
    pkg-config
    installShellFiles
  ];

  postInstall = ''
    installShellCompletion --cmd dfq \
      --bash <($out/bin/dfq completion bash) \
      --fish <($out/bin/dfq completion fish) \
      --zsh <($out/bin/dfq completion zsh)
  '';

  meta = {
    description = "a cli query tool for dockerfiles";
    homepage = "https://github.com/jpetrucciani/dfq";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "dfq";
  };
}
