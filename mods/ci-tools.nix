{ inputs, system }:
let
  pkgs = inputs.nixpkgs.legacyPackages.${system};
  finalOverlay = import ./final.nix pkgs pkgs;
  inherit (import ./hax.nix pkgs pkgs) hax;
  scriptPkgs = pkgs // { inherit hax; inherit (finalOverlay) vale-ci; };
  flake = { inherit inputs; };
  updatePkgs = pkgs // {
    inherit flake;
    inherit (finalOverlay) _nix;
    inherit (import ./override.nix pkgs pkgs) nix-update;
    inherit (import inputs.pog { inherit pkgs system; }) pog;
  };
in
{
  inherit ((import ../scripts.nix scriptPkgs pkgs).scripts)
    check_doc_links
    check_readme_index
    check_vale
    ;
  inherit (import ./pog/nix.nix updatePkgs pkgs) nupdate;
  iets = import ../pkgs/cli/iets.nix { inherit flake; inherit (pkgs) stdenv; };
}
