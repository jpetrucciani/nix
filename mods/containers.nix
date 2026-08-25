# this overlay injects [nix2container](https://github.com/nlewo/nix2container) into scope
final: _: {
  nix2container = final.flake.inputs.nix2container.packages.${final.stdenv.hostPlatform.system};
}
