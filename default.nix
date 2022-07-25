with builtins;
{ nixpkgs-json ? fromJSON (readFile ./sources/nixpkgs.json)
, nixpkgs ? fetchTarball {
    inherit (nixpkgs-json) sha256;
    url = "https://github.com/NixOS/nixpkgs/archive/${nixpkgs-json.rev}.tar.gz";
  }
, overlays ? [ ]
, config ? { }
}:
import nixpkgs { overlays = (import ./overlays.nix) ++ overlays; config = { allowUnfree = true; } // config; }
