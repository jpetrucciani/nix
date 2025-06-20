# [`goose`](https://github.com/block/goose) is an open-source, extensible AI agent that goes beyond code suggestions.
{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, dbus
, libgit2
, oniguruma
, openssl
, zlib
, zstd
, stdenv
, darwin
, xorg
, fetchurl
}:
let
  version = "1.0.2";
  cargoLock = fetchurl {
    url = "https://cobi.dev/static/cargolock/goose/${version}.lock";
    hash = "sha256-RyHs2pafBfbLDB+zDdaKVZhOpy/EefcTb6B+7pCnbng=";
  };
  tokenizerSlug = str: builtins.replaceStrings [ "/" ] [ "--" ] str;
  tokenizerData = {
    "Xenova/gpt-4o".sha256 = "sha256-Q6OtRhimqTj4wmFBVOoQwxrVOmLVaDrgsOYTNXXO8H4=";
    "Xenova/claude-tokenizer".sha256 = "sha256-wkFzffJLTn98mvT9zuKaDKkD3LKIqLdTvDRqMJKRF2c=";
  };
  tokenizerUrl = tokenizer: "https://huggingface.co/${tokenizer}/resolve/main/tokenizer.json";
  fetchedTokenizers = lib.mapAttrs
    (name: data:
      fetchurl {
        inherit (data) sha256;
        url = tokenizerUrl name;
        name = "${tokenizerSlug name}-tokenizer.json";
      }
    )
    tokenizerData;
  copyCommands = lib.concatStringsSep "\n" (map
    (name: "cp ${fetchedTokenizers.${name}} ./${tokenizerSlug name}/tokenizer.json")
    (builtins.attrNames tokenizerData)
  );
in
rustPlatform.buildRustPackage {
  inherit version;
  pname = "goose-ai";

  src = fetchFromGitHub {
    owner = "block";
    repo = "goose";
    rev = "v${version}";
    hash = "sha256-x4G+LE8M3JHNcWy9/4l5Xx+66ZtrKERDZM10K32ZMIE=";
  };

  cargoLock = {
    lockFile = cargoLock;
  };

  postPatch = ''
    ln -s ${cargoLock} Cargo.lock
  '';

  nativeBuildInputs = [
    pkg-config
    rustPlatform.bindgenHook
  ];

  buildInputs = [
    dbus
    libgit2
    oniguruma
    openssl
    zlib
    zstd
  ] ++ lib.optionals stdenv.isLinux [
    xorg.libxcb
  ];

  env = {
    RUSTONIG_SYSTEM_LIBONIG = true;
    ZSTD_SYS_USE_PKG_CONFIG = true;
  };

  preBuild = ''
    mkdir -p tokenizer_files
    cd tokenizer_files
    mkdir -p ${lib.concatStringsSep " " (map tokenizerSlug (builtins.attrNames tokenizerData))}
    ${copyCommands}
    cd ../
  '';

  # Skip tests that require filesystem write access or keyring functionality
  # as these fail in the Nix build sandbox
  checkFlags = [
    "--skip=providers::oauth::tests::test_token_cache"
    "--skip=config::base::tests::test_multiple_secrets"
    "--skip=config::base::tests::test_secret_management"
    "--skip=jetbrains::tests::test_capabilities"
    "--skip=jetbrains::tests::test_router_creation"
  ];

  meta = {
    description = "An open-source, extensible AI agent that goes beyond code suggestions - install, execute, edit, and test with any LLM";
    homepage = "https://github.com/block/goose";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "goose";
  };
}
