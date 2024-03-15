# This overlay provides new helpers for programming languages (like [vlang](https://vlang.io/) and [nim](https://nim-lang.org)). These helpers provide a default set of packages, and a way to build environments that link these packages into the build environment.
final: prev:
let
  inherit (final) concatStringsSep fetchFromGitHub stdenv;
  inherit (final) cmake libatomic_ops openssl python311;
in
rec {
  nimWithPackages =
    nim:
    packages:
    let
      nimPackages = final.callPackage ./lang/nim-packages.nix { };
      addPath = { src, sub ? "", ... }: ''--add-flags "--path:${src}${sub}"'';
      additionalPaths = map addPath (packages nimPackages);
    in
    nim.overrideAttrs (old: {
      wrapperArgs = old.wrapperArgs ++ additionalPaths;
    });
  nim = prev.nim.overrideAttrs (_: {
    passthru.withPackages = nimWithPackages prev.nim;
  });
  nim2 = prev.nim2.overrideAttrs (_: {
    passthru.withPackages = nimWithPackages prev.nim2;
  });

  vWithPackages =
    packages:
    let
      setVModules = "--set VMODULES $out/.vmod/";
      setVCache = "--set VCACHE /tmp/test";

      lnPackage = { src, name, sub ? "", ... }: "ln -s ${src}${sub} $out/.vmod/${name}";
      lnPackages = concatStringsSep "\n" (map lnPackage (packages (final.callPackage ./lang/v-packages.nix { })));
    in
    final.stdenv.mkDerivation {
      inherit (final.vlang) pname version;
      dontUnpack = true;

      propagatedNativeBuildInputs = [
        openssl
        libatomic_ops
      ];
      nativeBuildInputs = [ final.makeWrapper ];

      installPhase = ''
        mkdir -p $out/{.vmod,bin}
        ${lnPackages}
        makeWrapper ${final.vlang}/bin/v $out/bin/v ${setVModules} ${setVCache}
      '';
    };
  vlang = final.vlang.overrideAttrs (_: { passthru.withPackages = vWithPackages; });

  pycdc = stdenv.mkDerivation {
    name = "pycdc";
    src = fetchFromGitHub {
      owner = "jpetrucciani";
      repo = "pycdc";
      rev = "2e76e56420493bfc0807da06a87dfdda5217a5aa";
      sha256 = "sha256-FFPmQjruqwXNFr2VXzZAa/IFs7oGiZZUfm87ubJ3rQU=";
    };
    nativeBuildInputs = [
      cmake
      python311
    ];
  };
}
