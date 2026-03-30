{ lib, stdenvNoCC, fetchurl, installShellFiles, libiconv, darwin, cctools }:
let
  version = "0.1.0";
  inherit (stdenvNoCC.hostPlatform) system;

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
  strictDeps = true;
  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [
    installShellFiles
  ] ++ lib.optionals stdenvNoCC.isDarwin [
    cctools
    darwin.autoSignDarwinBinariesHook
  ];

  buildInputs = lib.optionals stdenvNoCC.isDarwin [ libiconv ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp $src $out/bin/geode
    chmod +x $out/bin/geode

    ${lib.optionalString stdenvNoCC.isDarwin ''
      old_libiconv="$(otool -L $out/bin/geode | awk '/libiconv\.2\.dylib/{print $1; exit}')"
      if [ -n "$old_libiconv" ] && [ "$old_libiconv" != "${libiconv}/lib/libiconv.2.dylib" ]; then
        install_name_tool -change "$old_libiconv" "${libiconv}/lib/libiconv.2.dylib" $out/bin/geode
      fi
    ''}

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
