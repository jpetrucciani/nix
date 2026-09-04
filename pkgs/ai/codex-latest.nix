{ codex
, fetchFromGitHub
, fetchurl
, lib
, refresh_codex_latest
, rustPlatform
, stdenv
}:
let
  version = "0.153.2";
  v8Version = "150.4.0";
  v8ReleaseBase = "https://github.com/openai/codex/releases/download/rusty-v8-v${v8Version}";
  v8ArchiveHashes = {
    aarch64-darwin = "sha256-AK27SHmISMd1UEQcaGc6XoUpuOG3PqvN7iMss5tA9KE=";
    aarch64-linux = "sha256-0VF+7UBUaFNwKbAF1f6ZfsdNXI01H5FrOm3yC30oEbo=";
    x86_64-linux = "sha256-o1x10fJuapg4haRbM0kKTr5U8FBQVosyuJz7QhswtYM=";
  };
  v8BindingHashes = {
    aarch64-darwin = "sha256-ylrfDPicmnCtRgrnNkiy/om3SqETs8t/dXtqArdYOU8=";
    aarch64-linux = "sha256-dyeCauR5vbZF6Acjn7EtH44uI956bPFvXuWSaQ0dhQY=";
    x86_64-linux = "sha256-dyeCauR5vbZF6Acjn7EtH44uI956bPFvXuWSaQ0dhQY=";
  };
  system = stdenv.hostPlatform.system;
  rustTarget = stdenv.hostPlatform.rust.rustcTarget;
  archiveHash = v8ArchiveHashes.${system}
    or (throw "Unsupported system for librusty_v8 ${v8Version}: ${system}");
  bindingHash = v8BindingHashes.${system}
    or (throw "Unsupported system for rusty_v8 binding ${v8Version}: ${system}");
  src = fetchFromGitHub {
    owner = "openai";
    repo = "codex";
    tag = "rust-v${version}";
    hash = "sha256-R97lEHS2XfMQNbAc9k8v7EbcQCnwxND7zhnK3EBsI3Y=";
  };
  librustyV8 = fetchurl {
    name = "librusty_v8-${v8Version}";
    url = "${v8ReleaseBase}/librusty_v8_ptrcomp_sandbox_release_${rustTarget}.a.gz";
    hash = archiveHash;
    meta.sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
  rustyV8Binding = fetchurl {
    name = "rusty_v8_binding-${v8Version}";
    url = "${v8ReleaseBase}/src_binding_ptrcomp_sandbox_release_${rustTarget}.rs";
    hash = bindingHash;
  };
in
codex.overrideAttrs (old: {
  inherit version src;

  postPatch = ''
    substituteInPlace Cargo.toml \
      --replace-fail 'lto = "thin"' "" \
      --replace-fail 'codegen-units = 4' ""
  '';

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit src;
    sourceRoot = "${src.name}/codex-rs";
    hash = "sha256-GG6kOXmCdq+bZLU2ul0DIVL8lDuweayvZvXn6+bcUZw=";
  };

  env = builtins.removeAttrs (old.env or { }) [ "LK_CUSTOM_WEBRTC" ] // {
    RUSTY_V8_ARCHIVE = librustyV8;
    RUSTY_V8_SRC_BINDING_PATH = rustyV8Binding;
  };

  passthru = (old.passthru or { }) // {
    updateScript = refresh_codex_latest;
  };

  meta = old.meta // {
    skipBuild = true;
  };
})
