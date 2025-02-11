{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable-small";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devenv = {
      url = "github:cachix/devenv/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-compat = {
      flake = false;
      url = "github:edolstra/flake-compat";
    };
    hex.url = "github:jpetrucciani/hex";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    kwb = {
      url = "github:kwbauson/cfg";
      inputs = {
        home-manager.follows = "home-manager";
        nixos-hardware.follows = "nixos-hardware";
        nixpkgs.follows = "nixpkgs";
      };
    };
    nix-darwin.flake = true;
    nix2container.url = "github:nlewo/nix2container";
    nixos-hardware.flake = true;
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-std.url = "github:chessai/nix-std";
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pnpm2nix.url = "github:nzbr/pnpm2nix-nzbr";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pog.url = "github:jpetrucciani/pog";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    uv2nix = {
      url = "github:adisbladis/uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, pog, hex, ... }:
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
      nix2containerPkgs = self.inputs.nix2container.packages.x86_64-linux;
      packages = forAllSystems
        (system: import self.inputs.nixpkgs {
          inherit system;
          overlays = [
            (_: _: { inherit machines; flake = self; nixpkgsRev = self.inputs.nixpkgs.rev; })
            self.inputs.poetry2nix.overlays.default
            (_: _: { inherit (self.inputs) uv2nix; })
            (_: _: { treefmt-nix = self.inputs.treefmt-nix.lib; })
            (_: prev: { inherit (import pog { pkgs = prev; }) _ pog; })
            (_: prev: { inherit (import hex { pkgs = prev; }) hex hexcast nixrender; })
          ] ++ import ./overlays.nix;
          config = {
            allowUnfree = true;
            permittedInsecurePackages = [
              "nodejs-16.20.2"
            ];
          };
        });
    in
    {
      inherit packages;
      inherit (nix2containerPkgs) nix2container;
      pins = self.inputs;
      devShells = forAllSystems (
        system: let pkgs = packages.${system}; in { default = pkgs.mkShell { buildInputs = with pkgs; [ jfmt nixup ]; }; }
      );

      nixosConfigurations = builtins.listToAttrs
        (map
          (name:
            let sys = if name == "andromeda" then "aarch64-linux" else "x86_64-linux"; in {
              inherit name;
              value = self.inputs.nixpkgs.lib.nixosSystem {
                pkgs = self.packages.${sys};
                specialArgs = { flake = self; machine-name = name; };
                modules = [
                  ./hosts/modules/servers/infinity.nix
                  ./hosts/${name}/configuration.nix
                  self.inputs.agenix.nixosModules.default
                  { programs.ssh.setXAuthLocation = lib.mkForce true; }
                ];
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
                ./hosts/modules/darwin/infinity.nix
                ./hosts/modules/darwin/koboldcpp.nix
                ./hosts/modules/darwin/llama-server.nix
                ./hosts/modules/darwin/mlx-vlm-api.nix
                ./hosts/modules/darwin/ollama.nix
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
