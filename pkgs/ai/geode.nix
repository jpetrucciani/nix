{ lib, stdenvNoCC, fetchurl, installShellFiles }:
let
  version = "0.1.0";
  system = stdenvNoCC.hostPlatform.system;

  artifacts = {
    x86_64-linux = {
      url = "https://static.g7c.us/geode/${version}/bin/x86_64-linux/geode";
      sha256 = "sha256-OAF7v6Xk1HpTxbHGJUsoFSSLS7g3p4HmtmqmXeh/r9k=";
    };
    aarch64-darwin = {
      url = "https://static.g7c.us/geode/${version}/bin/aarch64-darwin/geode";
      sha256 = "sha256-mlkatmXHfKBNIkK5Rdb57UN7b+yEKQ31vowkxwOxqkM=";
    };
  };
  artifact = artifacts.${system} or (throw "geode: unsupported system ${system}, supported: x86_64-linux, aarch64-darwin");
in
stdenvNoCC.mkDerivation {
  pname = "geode";
  inherit version;

  src = fetchurl artifact;
  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [
    installShellFiles
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp $src $out/bin/geode
    chmod +x $out/bin/geode

    installShellCompletion --cmd geode \
      --bash <($out/bin/geode completions bash) \
      --fish <($out/bin/geode completions fish) \
      --zsh <($out/bin/geode completions zsh)

    runHook postInstall
  '';

  meta = with lib; {
    description = "local-first semantic index toolkit";
    mainProgram = "geode";
    platforms = [ "x86_64-linux" "aarch64-darwin" ];
    maintainers = with lib.maintainers; [ jpetrucciani ];
  };
}
