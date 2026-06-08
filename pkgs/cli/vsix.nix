{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, xz
, zstd
, nix-update-script
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "vsix";
  version = "1.0.2";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "beeltec";
    repo = "vsix";
    tag = "v${finalAttrs.version}";
    hash = "sha256-zrnPg4spNQw/ASgGUUaKCGicoTr3XmXC3HPXnV8Cw88=";
  };

  cargoHash = "sha256-xQB1fua+J8jeG87oZuLcCNHyWJsy3yCkbbnf4nDpxPg=";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    xz
    zstd
  ];

  env = {
    ZSTD_SYS_USE_PKG_CONFIG = true;
  };

  preCheck = ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
  '';

  checkFlags = [
    # These hit the live Visual Studio Marketplace, which is unavailable in the Nix sandbox.
    "--skip=infrastructure::marketplace_tests::tests::test_download_extension"
    "--skip=infrastructure::marketplace_tests::tests::test_get_specific_extension"
    "--skip=infrastructure::marketplace_tests::tests::test_search_nginx_extensions"
  ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "A command-line utility that downloads and installs .vsix extensions into Visual Studio Code and Cursor";
    homepage = "https://github.com/beeltec/vsix";
    changelog = "https://github.com/beeltec/vsix/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "vsix";
  };
})
