# this overlay injects various javascript helpers into scope
final: prev: {
  pnpm2nix = (import ../flake-compat.nix).inputs.pnpm2nix.packages.${prev.stdenv.hostPlatform.system};
}
