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
    # _compat.inputs.pnpm2nix.overlays.default
    (_: _: { treefmt-nix = _compat.inputs.treefmt-nix.lib; })
    (_: _: { inherit (_compat.inputs) uv2nix; })
    (_: prev: { inherit (import _compat.inputs.pog { pkgs = prev; }) _ pog; })
    (_: prev: { inherit (import _compat.inputs.hex { pkgs = prev; }) hex hexcast nixrender; })
    (_: _: {
      machines = {
        nixos = [
          "andromeda"
          "edge"
          "luna"
          "milkyway"
          "neptune"
          "phobos"
          "polaris"
          "terra"
          "titan"
        ];
        darwin = [
          "charon"
          "m1max"
          "nyx0"
          "pluto"
          "styx"
        ];
      };
    })
  ] ++ (import ./overlays.nix) ++ overlays;
  config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "nodejs-16.20.2"
    ];
  } // config;
}
