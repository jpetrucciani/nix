# [awl](https://github.com/jpetrucciani/awl) is a small, sharp tool for AWS operations
{ lib
, rustPlatform
, fetchFromGitHub
, nix-update-script
, installShellFiles
, gofakes3
, goaws
, cacert
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "awl";
  version = "0.0.7";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "jpetrucciani";
    repo = "awl";
    tag = "v${finalAttrs.version}";
    hash = "sha256-UX4/kj79VKfWfjsx3GKuoxRavAk/njTmasxOuEKZA4M=";
  };

  cargoHash = "sha256-9AgyWa1QQF6bi4E6k6pik0hU63JoNUPpATBgVOwUzaM=";

  passthru.updateScript = nix-update-script { };

  nativeBuildInputs = [
    installShellFiles
  ];

  nativeCheckInputs = [ gofakes3 goaws ];
  env.SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";

  postInstall = ''
    installShellCompletion --cmd awl \
      --bash <($out/bin/awl completions bash) \
      --fish <($out/bin/awl completions fish) \
      --zsh <($out/bin/awl completions zsh)
  '';

  meta = {
    description = "A small, sharp tool for AWS operations";
    homepage = "https://github.com/jpetrucciani/awl";
    changelog = "https://github.com/jpetrucciani/awl/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "awl";
  };
})
