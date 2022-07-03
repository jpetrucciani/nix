final: prev:
with prev;
with builtins; rec {
  nimWithPackages =
    packages:
    let
      addPath = { src, name, sub ? "", meta ? { }, ... }: ''--add-flags "--path:${src}${sub}"'';
      additionalPaths = map addPath (packages (prev.callPackage ./pkgs/nim-packages.nix { }));
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
      lnPackages = concatStringsSep "\n" (map lnPackage (packages (prev.callPackage ./pkgs/v-packages.nix { })));
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

}
