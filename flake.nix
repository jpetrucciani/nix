{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable-small";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-compat = {
      flake = false;
      url = "github:edolstra/flake-compat";
    };
    hex.url = "github:jpetrucciani/hex";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.flake = true;
    nix2container.url = "github:nlewo/nix2container?ref=d6d89f6dd7ed98b56f7dd783047983ef941bf4f9";
    nixos-hardware.flake = true;
    nix-std.url = "github:chessai/nix-std";
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pnpm2nix.url = "github:nzbr/pnpm2nix-nzbr";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };
    pog.url = "github:jpetrucciani/pog";
    treefmt-nix.url = "github:jpetrucciani/treefmt-nix";
    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      flake = false;
    };
    # uv
    uv2nix = {
      url = "github:adisbladis/uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [ "https://cache.g7c.us" ];
    extra-trusted-public-keys = [ "cache.g7c.us:dSWpE2B5zK/Fahd7npIQWM4izRnVL+a4LiCAnrjdoFY=" ];
  };

  outputs = { self, ... }:
    let
      inherit (self.inputs.nixpkgs) lib;
      inherit (constants) machines;
      constants = import ./hosts/constants.nix;
      forAllSystems = lib.genAttrs [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      nix2containerPkgs = self.inputs.nix2container.packages.x86_64-linux;
      packageSets = forAllSystems
        (system: import ./. { flake = self; inherit system; });
      upstreamPackageSets = forAllSystems
        (system: import self.inputs.nixpkgs {
          inherit system;
          config = packageSets.${system}.config;
        });
      overlayDelta = forAllSystems
        (system: import ./overlay-delta.nix {
          local = packageSets.${system};
          overlays = import ./overlays.nix;
          root = ./.;
          upstream = upstreamPackageSets.${system};
        });
      customPackageDrvPaths = forAllSystems
        (system: lib.mapAttrs (_: package: package.drvPath) packageSets.${system}.__j_eval_packages);
      autoUpdatePackages = forAllSystems
        (system: builtins.attrNames (lib.filterAttrs
          (_: package: package ? passthru && package.passthru ? updateScript)
          packageSets.${system}.__j_packages));
      packages = forAllSystems
        (system: packageSets.${system}.__j_packages);
      foundryConfiguration = self.inputs.nixpkgs.lib.nixosSystem {
        pkgs = packageSets.x86_64-linux;
        specialArgs = { flake = self; machine-name = "foundry"; };
        modules = [
          ./hosts/foundry/configuration.nix
          ./hosts/foundry/images.nix
        ];
      };
      foundryImageVariants = foundryConfiguration.config.system.build.images;
    in
    {
      inherit packages;
      legacyPackages = packageSets;
      lib = lib // { inherit autoUpdatePackages customPackageDrvPaths overlayDelta; };
      inherit (nix2containerPkgs) nix2container;
      pins = self.inputs;
      devShells = forAllSystems (
        system:
        let
          pkgs = packageSets.${system};
        in
        {
          default = pkgs.mkShell {
            name = "nix";
            buildInputs = with pkgs; [
              bun
              jfmt
              nixup
            ];
          };
        }
      );

      checks = forAllSystems (
        system:
        let
          pkgs = packageSets.${system};
          pogScriptGroups = lib.filterAttrs
            (name: value: lib.hasSuffix "_pog_scripts" name && builtins.isList value)
            pkgs;
          pogScripts = lib.concatLists (builtins.attrValues pogScriptGroups);
          pogScriptSources = map
            (script:
              pkgs.writeText
                "${script.meta.mainProgram or script.name}.bash"
                script.text)
            pogScripts;
          checkPogScripts = pkgs.runCommand "check-pog-scripts"
            {
              nativeBuildInputs = [ pkgs.shellcheck ];
            }
            ''
              checked=0
              for script in ${lib.escapeShellArgs pogScriptSources}; do
                echo "checking $script"
                ${pkgs.bash}/bin/bash -n "$script"
                shellcheck --shell=bash "$script"
                checked=$((checked + 1))
              done

              if [ "$checked" -eq 0 ]; then
                echo "no exported pog scripts were discovered" >&2
                exit 1
              fi

              printf 'validated %s pog scripts\n' "$checked" > "$out"
            '';
        in
        lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          check-pog-scripts = checkPogScripts;
          snowball-api-manifest = pkgs.snowball.api.tests.manifest;
          snowball-api-script = pkgs.snowball.api.tests.script;
          snowball-api-rpm = pkgs.snowball.api.tests.rpm;
          snowball-api-rpm-portable = pkgs.snowball.api.tests.rpmPortable;
          snowball-api-uv-manifest = pkgs.snowball.api-uv.tests.manifest;
          snowball-api-uv-script = pkgs.snowball.api-uv.tests.script;
          snowball-api-uv-rpm = pkgs.snowball.api-uv.tests.rpm;
          snowball-api-uv-rpm-portable = pkgs.snowball.api-uv.tests.rpmPortable;
          snowball-manifest = pkgs.snowball.earlyoom.tests.manifest;
          snowball-script = pkgs.snowball.earlyoom.tests.script;
          snowball-rpm = pkgs.snowball.earlyoom.tests.rpm;
          snowball-rpm-portable = pkgs.snowball.earlyoom.tests.rpmPortable;
          snowball-nvme-manifest = pkgs.snowball.nvme-exporter.tests.manifest;
          snowball-nvme-script = pkgs.snowball.nvme-exporter.tests.script;
          snowball-nvme-rpm = pkgs.snowball.nvme-exporter.tests.rpm;
          snowball-nvme-rpm-portable = pkgs.snowball.nvme-exporter.tests.rpmPortable;
        }
      );

      nixosConfigurations = builtins.listToAttrs
        (map
          (name:
            {
              inherit name;
              value = self.inputs.nixpkgs.lib.nixosSystem {
                pkgs = packageSets.x86_64-linux;
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
              pkgs = packageSets.aarch64-darwin;
              specialArgs = { flake = self; machine-name = name; };
              modules = [
                ./hosts/common_darwin.nix
                ./hosts/${name}/configuration.nix
              ] ++ import ./hosts/modules/darwin;
            };
          })
          machines.darwin
        );

      osImages = lib.getAttrs [
        "amazon"
        "azure"
        "digital-ocean"
        "google-compute"
        "google-compute-cuda"
        "hyperv"
        "iso"
        "iso-installer"
        "proxmox"
        "virtualbox"
        "vmware"
      ]
        foundryImageVariants;

    };
}
