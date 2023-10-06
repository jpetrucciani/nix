{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    devenv = {
      url = "github:cachix/devenv/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-compat = {
      flake = false;
      url = "github:edolstra/flake-compat";
    };
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    kwb = {
      url = "github:kwbauson/cfg";
      inputs = {
        home-manager.follows = "home-manager";
        nix-darwin.follows = "nix-darwin";
        nixos-hardware.follows = "nixos-hardware";
        nixpkgs.follows = "nixpkgs";
      };
    };
    nix = {
      url = "nix/2.18.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix2container = {
      url = "github:nlewo/nix2container";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.flake = true;
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vscode-server = {
      url = "github:msteen/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, ... }:
    let
      inherit (self.inputs.nixpkgs) lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;
      machines = {
        nixos = [
          "andromeda"
          "edge"
          "luna"
          "milkyway"
          "neptune"
          "phobos"
          "terra"
          "titan"
        ];
        darwin = [
          "charon"
          "m1max"
          "pluto"
        ];
      };
      nix2containerPkgs = self.inputs.nix2container.packages.x86_64-linux;
    in
    {
      inherit (nix2containerPkgs) nix2container;
      pins = self.inputs;
      packages = forAllSystems
        (system: import self.inputs.nixpkgs {
          inherit system;
          overlays = [ (final: prev: { inherit machines; flake = self; }) self.inputs.nix.overlays.default ] ++ import ./overlays.nix;
          config = {
            allowUnfree = true;
            permittedInsecurePackages = [
              "nodejs-16.20.2"
            ];
          };
        });

      nixosConfigurations = builtins.listToAttrs
        (map
          (name:
            let sys = if name == "andromeda" then "aarch64-linux" else "x86_64-linux"; in {
              inherit name;
              value = self.inputs.nixpkgs.lib.nixosSystem {
                pkgs = self.packages.${sys};
                specialArgs = { flake = self; machine-name = name; };
                modules = [ ./hosts/${name}/configuration.nix ];
              };
            })
          machines.nixos
        );

      darwinConfigurations = builtins.listToAttrs
        (map
          (name: {
            inherit name;
            value = self.inputs.nix-darwin.lib.darwinSystem {
              pkgs = self.packages.aarch64-darwin;
              specialArgs = { flake = self; machine-name = name; };
              modules = [
                ./hosts/common_darwin.nix
                ./hosts/${name}/configuration.nix
              ];
            };
          })
          machines.darwin
        );

      osGenerators = builtins.listToAttrs
        (map
          (name: {
            inherit name;
            value = self.inputs.nixos-generators.nixosGenerate {
              pkgs = self.packages.x86_64-linux;
              specialArgs = { flake = self; machine-name = name; };
              modules = [ ./hosts/foundry/configuration.nix ];
              format = name;
            };
          })
          [
            "amazon"
            "azure"
            "do"
            "gce"
            "hyperv"
            "install-iso"
            "install-iso-hyperv"
            "iso"
            "proxmox"
            "virtualbox"
            "vmware"
          ]);
    };
}
