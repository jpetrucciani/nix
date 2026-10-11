{ lib
, rustPlatform
, fetchFromGitHub
, nix-update-script
, installShellFiles
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "prism";
  version = "0.0.5";

  src = fetchFromGitHub {
    owner = "jpetrucciani";
    repo = "prism";
    tag = "v${finalAttrs.version}";
    hash = "sha256-GOgszh0qKYcqlqKMWwSgVjQmcOAW+MzpsqZVEGQOZwY=";
  };

  cargoHash = "sha256-NvUJUmQuDLjwpMvH+9dWpPDbv9glm32OxrZ50U/JQwg=";

  passthru.updateScript = nix-update-script { };

  nativeBuildInputs = [
    installShellFiles
  ];

  postInstall = ''
    installShellCompletion --cmd prism \
      --bash <($out/bin/prism completions bash) \
      --fish <($out/bin/prism completions fish) \
      --zsh <($out/bin/prism completions zsh)
  '';

  meta = {
    description = "small text manipulation cli";
    homepage = "https://github.com/jpetrucciani/prism";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "prism";
  };
})
