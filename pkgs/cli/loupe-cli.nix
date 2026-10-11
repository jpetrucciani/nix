{ lib
, rustPlatform
, fetchFromGitHub
, fetchurl
, cacert
, cmake
, installShellFiles
, python3
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "loupe";
  version = "0.0.2";

  src = fetchFromGitHub {
    owner = "jpetrucciani";
    repo = "loupe";
    tag = "v${finalAttrs.version}";
    hash = "sha256-bH/2LGI3JlJ8e8VD8cqPIu7hHaTnrTeKYMP3OABKNfQ=";
  };

  cargoHash = "sha256-2YcdytfCo3WnPeYCdHmdFfxSPbPfA14nLrsY0SC0Fqc=";

  buildFeatures = [ "mcp" "parquet" ];

  nativeBuildInputs = [ cmake installShellFiles ];
  nativeCheckInputs = [ python3 ];
  dontUseCmakeConfigure = true;
  dontUseCargoParallelTests = true;

  # Avoid repeating cross-crate LTO for every test executable, as upstream does.
  env = {
    CARGO_PROFILE_RELEASE_LTO = "off";
    CARGO_PROFILE_RELEASE_CODEGEN_UNITS = "16";
    SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
  };

  preCheck =
    let
      tokenizer = fetchurl {
        url = "https://huggingface.co/Cloudflare/clef-flash/resolve/17f0b0ad64efb65d273590632833508766b2aae6/tokenizer.json";
        hash = "sha256-BrlQk1LSr1A4GrIkfgg7gNMtXAq6kcJyyp/3Kbag5SM=";
      };
    in
    ''
      export LOUPE_TEST_TOKENIZER=${tokenizer}
      export LOUPE_TOKENIZER=${tokenizer}
    '';

  postInstall = ''
    install -Dm644 LICENSE "$out/share/doc/loupe/LICENSE"
    install -Dm644 THIRD_PARTY_NOTICES.md "$out/share/doc/loupe/THIRD_PARTY_NOTICES.md"
    install -Dm644 licenses/Apache-2.0.txt "$out/share/doc/loupe/licenses/Apache-2.0.txt"
    installShellCompletion --cmd loupe \
      --bash <("$out/bin/loupe" completions bash) \
      --zsh <("$out/bin/loupe" completions zsh) \
      --fish <("$out/bin/loupe" completions fish)
    "$out/bin/loupe" man >loupe.1
    installManPage loupe.1
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/loupe" --version | grep -Fx 'loupe ${finalAttrs.version}'
    "$out/bin/loupe" --help >/dev/null
    test -s "$out/share/bash-completion/completions/loupe.bash"
    test -s "$out/share/man/man1/loupe.1.gz"
    runHook postInstallCheck
  '';

  meta = {
    description = "Semantic Unix filters for decision models";
    homepage = "https://github.com/jpetrucciani/loupe";
    license = [ lib.licenses.mit lib.licenses.asl20 ];
    maintainers = [ lib.maintainers.jpetrucciani ];
    mainProgram = "loupe";
    platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
  };
})
