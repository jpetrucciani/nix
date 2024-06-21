{ _compat ? import ./flake-compat.nix
, nixpkgs ? _compat.inputs.nixpkgs
, overlays ? [ ]
, config ? { }
, system ? builtins.currentSystem
}:
import nixpkgs {
  inherit system;
  overlays = [
    (_: _: { nixpkgsRev = nixpkgs.rev; })
    (_: _: { _std = _compat.inputs.nix-std.lib; })
    _compat.inputs.poetry2nix.overlays.default
    _compat.inputs.pnpm2nix.overlays.default
  ] ++ (import ./overlays.nix) ++ overlays;
  config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "nodejs-16.20.2"
    ];
  } // config;
}
