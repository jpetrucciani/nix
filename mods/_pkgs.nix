# This overlay allows me to load the custom packages I've built in my [pkgs/](../pkgs/) directory
final: prev:
let
  inherit (builtins) pathExists readDir;
  inherit (prev.lib) concatStringsSep hasSuffix listToAttrs optionalString pathIsDirectory removeSuffix;
  inherit (prev.lib.attrsets) collect mapAttrs;
  inherit (prev.pkgs) callPackage;
  fetchLibrustyV8 =
    { version
    , hashes
    , features ? [ ]
    , profile ? "release"
    }:
    let
      inherit (final.stdenv.hostPlatform) system;
      featureSuffix = optionalString (features != [ ]) "${concatStringsSep "_" features}_";
    in
    final.fetchurl {
      name = "librusty_v8-${version}";
      url = "https://github.com/denoland/rusty_v8/releases/download/v${version}/librusty_v8_${featureSuffix}${profile}_${final.stdenv.hostPlatform.rust.rustcTarget}.a.gz";
      hash = hashes.${system} or (throw "Unsupported system for librusty_v8 ${version}: ${system}");
      meta = {
        inherit version;
        sourceProvenance = with final.lib.sourceTypes; [ binaryNativeCode ];
      };
    };
  _custom = p:
    if hasSuffix ".nix" p || pathExists (p + "/default.nix")
    then { name = removeSuffix ".nix" (baseNameOf (toString p)); value = p; __stop = true; }
    else
      if pathIsDirectory p
      then mapAttrs (p': _: _custom (p + "/${p'}")) (readDir p)
      else null;
  custom = mapAttrs (_: p: callPackage p { inherit fetchLibrustyV8; }) (listToAttrs (collect (x: x.__stop or false) (_custom ../pkgs)));
in
{
  inherit custom fetchLibrustyV8;
} // custom
