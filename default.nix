{ sources ? import ./nix/sources.nix
, nixpkgs ? sources.nixpkgs
}:
import nixpkgs { overlays = import ./overlays.nix; }
