final: prev:
let
  inherit (builtins) listToAttrs pathExists readDir;
  inherit (prev.lib) hasSuffix isDerivation pathIsDirectory removeSuffix;
  inherit (prev.lib.attrsets) collect mapAttrs';
  inherit (prev.pkgs) callPackage;
  custom = listToAttrs (map (x: { name = x.pname; value = x; }) (collect isDerivation (_custom ../pkgs)));
  _custom = x:
    if hasSuffix ".nix" x || pathExists (x + "/default.nix")
    then callPackage x { inherit (prev) pkgs; }
    else
      if pathIsDirectory x
      then (mapAttrs' (k: _: { name = removeSuffix ".nix" k; value = _custom (x + "/${k}"); }) (readDir x))
      else null;
in
{
  inherit custom;
}
# // custom
