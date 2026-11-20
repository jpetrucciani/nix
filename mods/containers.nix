# this overlay injects [nix2container](https://github.com/nlewo/nix2container) into scope
final: _:
let
  inherit (final.stdenv.hostPlatform) system;
  input = final.flake.inputs.nix2container;
  inherit (input.inputs) nixpkgs;
  pkgs = nixpkgs.legacyPackages.${system};

  # The vendored file is the normalized output of this fetchpatch2 call.
  patchName = "c2254c998433cf02af60bf0292042bd80b96a77e.patch";
  fetchpatch2 = args:
    if (args.url or null) == "https://github.com/nlewo/image/commit/${patchName}" then
      builtins.path
        {
          path = ./patches/nix2container/skopeo-nix-transport.patch;
          name = patchName;
          recursive = false;
          inherit (args) sha256;
        }
    else pkgs.fetchpatch2 args;

  outputs = (import "${input}/flake.nix").outputs (input.inputs // {
    self = input;
    nixpkgs = nixpkgs // {
      legacyPackages = nixpkgs.legacyPackages // {
        ${system} = pkgs // { inherit fetchpatch2; };
      };
    };
  });
in
{
  nix2container = outputs.packages.${system};
}
