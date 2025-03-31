# this overlay injects [nix2container](https://github.com/nlewo/nix2container) into scope
final: prev: {
  nix2container = (import ../flake-compat.nix).inputs.nix2container.packages.${final.system};
}
