{ flake ? import ./flake-compat.nix
, nixpkgs ? flake.inputs.nixpkgs
, overlays ? [ ]
, config ? { }
, system ? builtins.currentSystem
}:
import nixpkgs {
  inherit system;
  overlays = [
    (_: _: { inherit flake; nixpkgsRev = nixpkgs.rev; })
    (_: _: { _std = flake.inputs.nix-std.lib; })
    flake.inputs.poetry2nix.overlays.default
    (_: _: { treefmt-nix = flake.inputs.treefmt-nix.lib; })
    (_: _: { inherit (flake.inputs) uv2nix pyproject-nix pyproject-build-systems; })
    (final: _: { inherit (import flake.inputs.pog { pkgs = final; }) _ pog; })
    (final: _: let _hex = import flake.inputs.hex { pkgs = final; }; in { inherit (_hex) hex hexcast nixrender; hex_deps = _hex.deps; })
    (_: _: { inherit (import ./hosts/constants.nix) machines; })
    (final: _: { detsys = flake.inputs.determinate.packages.${system}; })
  ] ++ (import ./overlays.nix) ++ overlays;
  config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "nodejs-16.20.2"
      "openssl-1.1.1w"
    ];
  } // config;
}
