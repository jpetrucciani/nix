{ _compat ? import ./flake-compat.nix
, nixpkgs ? _compat.inputs.nixpkgs
, overlays ? [ ]
, config ? { }
, system ? builtins.currentSystem
}:
import nixpkgs {
  inherit system;
  overlays = [ (_: _: { nixpkgsRev = nixpkgs.rev; }) ] ++ (import ./overlays.nix) ++ overlays;
  config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "nodejs-16.20.2"
    ];
  } // config;
}
