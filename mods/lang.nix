final: prev:
with prev;
rec {
  nimWithPackages =
    packages:
    let
      nimPackages = prev.callPackage ./lang/nim-packages.nix { };
      addPath = { src, sub ? "", ... }: ''--add-flags "--path:${src}${sub}"'';
      additionalPaths = map addPath (packages nimPackages);
    in
    prev.nim.overrideAttrs (old: {
      wrapperArgs = old.wrapperArgs ++ additionalPaths;
    });
  nim = prev.nim.overrideAttrs (_: {
    passthru.withPackages = nimWithPackages;
  });

  vWithPackages =
    packages:
    let
      setVModules = "--set VMODULES $out/.vmod/";
      setVCache = "--set VCACHE /tmp/test";

      lnPackage = { src, name, sub ? "", ... }: "ln -s ${src}${sub} $out/.vmod/${name}";
      lnPackages = concatStringsSep "\n" (map lnPackage (packages (prev.callPackage ./lang/v-packages.nix { })));
    in
    prev.stdenv.mkDerivation {
      inherit (prev.vlang) pname version;
      dontUnpack = true;

      propagatedNativeBuildInputs = [
        openssl
        libatomic_ops
      ];
      nativeBuildInputs = [ prev.makeWrapper ];

      installPhase = ''
        mkdir -p $out/{.vmod,bin}
        ${lnPackages}
        makeWrapper ${prev.vlang}/bin/v $out/bin/v ${setVModules} ${setVCache}
      '';
    };
  vlang = prev.vlang.overrideAttrs (_: { passthru.withPackages = vWithPackages; });

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
