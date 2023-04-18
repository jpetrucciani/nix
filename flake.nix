{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv/latest";
    flake-compat = {
      flake = false;
      url = "github:edolstra/flake-compat";
    };
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix2container.url = "github:nlewo/nix2container";
    nixos-hardware.flake = true;
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vscode-server.url = "github:msteen/nixos-vscode-server";
    kwb.url = "github:kwbauson/cfg";
  };

  outputs = { self, ... }:
    let
      inherit (self.inputs.nixpkgs) lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;
    in
    {
      packages = forAllSystems
        (system: import self.inputs.nixpkgs {
          inherit system;
          overlays = import ./overlays.nix;
          config = { allowUnfree = true; };
        });

      nixosConfigurations = builtins.listToAttrs
        (map
          (name: {
            inherit name; value = self.inputs.nixpkgs.lib.nixosSystem {
            pkgs = self.packages.x86_64-linux;
            specialArgs = { machine-name = name; };
            modules = [ ./hosts/${name}/configuration.nix ];
          };
          })
          [
            "andromeda"
            "bedrock"
            "granite"
            "luna"
            "milkyway"
            "neptune"
            "phobos"
            "terra"
            "titan"
            "ymir"
          ]);

      darwinConfigurations = builtins.listToAttrs
        (map
          (name: {
            inherit name; value = self.inputs.nix-darwin.lib.darwinSystem {
            pkgs = self.packages.aarch64-darwin;
            specialArgs = { machine-name = name; };
            modules = [
              ./hosts/${name}/configuration.nix
            ];
          };
          })
          [
            "charon"
            "pluto"
            "m1max"
          ]);
    };
}
