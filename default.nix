{ nixpkgs ? (import ./flake-compat.nix).inputs.nixpkgs
, overlays ? [ ]
, config ? { }
, system ? builtins.currentSystem
}:
import nixpkgs {
  inherit system;
  overlays = (import ./overlays.nix) ++ overlays;
  config = { allowUnfree = true; } // config;
}
