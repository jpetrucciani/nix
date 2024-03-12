final: prev:
let
  inherit (final.lib) elem all id isDerivation;
  inherit (final.lib.attrsets) filterAttrs;
  checked_packages = filterAttrs
    (_: pkg: all id [
      (isDerivation pkg)
      (elem final.system pkg.meta.platforms)
      (!pkg.meta.broken or false)
      (!pkg.meta.skipBuild or false)
    ])
    prev.custom;
in
{
  foundry = import ./foundry.nix { pkgs = prev; };
  __j_custom = prev.buildEnv {
    name = "__j_custom";
    paths = (prev.lib.attrsets.attrValues checked_packages) ++ [ prev.hex prev.nix (prev.python311.withPackages prev.hax.basePythonPackages) ];
  };
}
