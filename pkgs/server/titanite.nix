{ lib, stdenvNoCC, fetchurl, installShellFiles }:
let
  version = "0.1.1";
  inherit (stdenvNoCC.hostPlatform) system;

  artifacts = {
    x86_64-linux = {
      url = "https://static.g7c.us/titanite/${version}/bin/x86_64-linux/titanite";
      sha256 = "sha256-U6+AyDb2Y1GEuEqQB1vsJ4Er7ZPROdPj7hdIclBX3O0=";
    };
  };
  artifact = artifacts.${system} or (throw "titanite: unsupported system ${system}, supported: x86_64-linux, aarch64-darwin");
in
stdenvNoCC.mkDerivation {
  pname = "titanite";
  inherit version;

  src = fetchurl artifact;
  strictDeps = true;
  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [
    installShellFiles
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp $src $out/bin/titanite
    chmod +x $out/bin/titanite

    installShellCompletion --cmd titanite \
      --bash <($out/bin/titanite completions bash) \
      --fish <($out/bin/titanite completions fish) \
      --zsh <($out/bin/titanite completions zsh)

    runHook postInstall
  '';

  meta = with lib; {
    description = "titanite is a policy-aware DNS service for homelabs and small production networks";
    mainProgram = "titanite";
    platforms = [ "x86_64-linux" ];
    maintainers = with lib.maintainers; [ jpetrucciani ];
  };
}
