final: prev: {
  foundry = import ./foundry.nix { pkgs = prev; };
  nix2container = (import ../flake-compat.nix).inputs.nix2container.packages.${prev.system};
}
