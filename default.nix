with builtins;
{ nixpkgs-json ? fromJSON (readFile ./sources/nixpkgs.json)
, nixpkgs ? fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${nixpkgs-json.rev}.tar.gz";
    sha256 = nixpkgs-json.sha256;
  }
}:
import nixpkgs { overlays = import ./overlays.nix; }
