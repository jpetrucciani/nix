# [awl](https://github.com/jpetrucciani/awl) is a small, sharp tool for AWS operations
{ lib
, rustPlatform
, fetchFromGitHub
, nix-update-script
, installShellFiles
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "awl";
  version = "0.0.5";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "jpetrucciani";
    repo = "awl";
    tag = "v${finalAttrs.version}";
    hash = "sha256-FcET55ZS7RKnz1kjqwL7egV4obGr5FCWIx09lQHPFQs=";
  };

  cargoHash = "sha256-Bysj6Y+YX5rRcFuJPr3Xy36oWSkjwJDoCfCS8tA9HD0=";

  passthru.updateScript = nix-update-script { };

  nativeBuildInputs = [
    installShellFiles
  ];

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
