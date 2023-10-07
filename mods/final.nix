final: prev: {
  foundry = import ./foundry.nix { pkgs = prev; };
  __j_custom = prev.buildEnv {
    name = "__j_custom";
    paths = (prev.lib.attrsets.attrValues prev.custom) ++ [ prev.hex prev.nix (prev.python311.withPackages prev.hax.basePythonPackages) ];
  };
}
