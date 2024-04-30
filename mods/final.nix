# This overlay acts as the last overlay, allowing me to add attributes after every other overlay in this repo
final: prev:
let
  inherit (final.lib) elem all id isDerivation;
  inherit (final.lib.lists) remove;
  inherit (final.lib.attrsets) filterAttrs;
  checked_packages = filterAttrs
    (_: pkg: all id [
      (isDerivation pkg)
      (elem final.system pkg.meta.platforms or [ final.system ])
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

  poetry-helpers = {
    add_propagated = pkg: propagated: pkg.overridePythonAttrs (old: {
      propagatedBuildInputs = (old.propagatedBuildInputs or [ ]) ++ propagated;
    });
    remove_propagated = pkg: _remove: pkg.overridePythonAttrs (old: {
      propagatedBuildInputs = remove _remove (old.propagatedBuildInputs or [ ]);
    });
    no_wheel = pkg: pkg.override { preferWheel = false; };
    no_check = pkg: pkg.overridePythonAttrs (_: { doCheck = false; });
  };
}
