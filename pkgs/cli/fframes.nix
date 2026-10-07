{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "fframes";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "dmtrKovalenko";
    repo = "fframes";
    tag = "v${finalAttrs.version}";
    hash = "sha256-m5XTWEgDsQ5KsFVfQA5OPeaGkoqn7eg3c8hYN+0Kn3U=";
  };

  cargoHash = "sha256-f+2C46AWMASgy05my9mRRxDVwnSryQDzGViNgtMoa+Q=";

  # The workspace config sets renderer-specific macOS deployment and linker flags.
  postUnpack = ''
    rm "$sourceRoot/.cargo/config.toml"
  '';

  cargoBuildFlags = [ "--package=cargo-fframes" ];
  cargoTestFlags = [ "--package=cargo-fframes" ];

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    "$out/bin/cargo-fframes" fframes --help >/dev/null
    "$out/bin/cargo-fframes" fframes new smoke-video --yes --backend cpu \
      --dir "$TMPDIR/fframes-smoke"
    test -s "$TMPDIR/fframes-smoke/Cargo.toml"
    test -s "$TMPDIR/fframes-smoke/src/lib.rs"
    test -s "$TMPDIR/fframes-smoke/src/main.rs"
    test -s "$TMPDIR/fframes-smoke/media/DMSans-Medium.ttf"

    runHook postInstallCheck
  '';

  meta = {
    description = "Create Rust and SVG video projects with cargo fframes";
    homepage = "https://github.com/dmtrKovalenko/fframes";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "cargo-fframes";
    platforms = lib.platforms.unix;
  };
})
