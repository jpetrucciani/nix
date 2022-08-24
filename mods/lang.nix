final: prev:
with prev;
with builtins; rec {
  nimWithPackages =
    packages:
    let
      addPath = { src, name, sub ? "", meta ? { }, ... }: ''--add-flags "--path:${src}${sub}"'';
      additionalPaths = map addPath (packages (prev.callPackage ./lang/nim-packages.nix { }));
    in
    prev.nim.overrideAttrs (old: {
      wrapperArgs = old.wrapperArgs ++ additionalPaths;
    });
  nim = prev.nim.overrideAttrs (_: { passthru.withPackages = nimWithPackages; });

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
      rev = "da523cf1909563f34a9b9465d18b4a011c463bea";
      sha256 = "sha256-pyS0PF8AQ7U5Gmt8rt7HymnQ+XenRI6Nv4/PVHZtqus=";
    };
    propagatedBuildInputs = [ cmake python310 ];
  };

}
