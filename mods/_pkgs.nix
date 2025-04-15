# This overlay allows me to load the custom packages I've built in my [pkgs/](../pkgs/) directory
final: prev:
let
  inherit (builtins) pathExists readDir;
  inherit (prev.lib) hasSuffix listToAttrs pathIsDirectory removeSuffix;
  inherit (prev.lib.attrsets) collect mapAttrs;
  inherit (prev.pkgs) callPackage;
  _custom = p:
    if hasSuffix ".nix" p || pathExists (p + "/default.nix")
    then { name = removeSuffix ".nix" (baseNameOf (toString p)); value = p; __stop = true; }
    else
      if pathIsDirectory p
      then mapAttrs (p': _: _custom (p + "/${p'}")) (readDir p)
      else null;
  custom = mapAttrs (_: p: callPackage p { }) (listToAttrs (collect (x: x.__stop or false) (_custom ../pkgs)));
in
{
  inherit custom;
} // custom
