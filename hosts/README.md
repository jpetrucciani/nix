# hosts

This directory contains concrete machine definitions, shared host defaults, and reusable host modules.

Most entries here are one of three things:

- a NixOS host directory with `configuration.nix` and `hardware-configuration.nix`
- a nix-darwin host directory with `configuration.nix`
- a shared profile or helper file used by several machines

---

## In this directory

### [cy1-nix-01/](./cy1-nix-01/)

This is a NixOS work machine on the BlackEdge network.

### [edge/](./edge/)

This is a large VM-oriented NixOS host.

### [foundry/](./foundry/)

This directory contains the shared image-builder profile used for cloud images and ISOs.

### [luna/](./luna)

This is a bare-metal physical nixos server!

### [m1max/](./m1max)

This is my work M1 Max MacBook, managed with nix-darwin and Home Manager.

### [mars/](./mars)

This is a bare-metal physical nixos server!

### [milkyway/](./milkyway/)

This is a NixOS install running on top of WSL2.

### [modules/](./modules)

Additional modules for use in the various NixOS and nix-darwin host configurations.

### [neptune/](./neptune)

This is a bare-metal nixos server.

### [nyx0/](./nyx0)

This is an M4 Mac mini managed with nix-darwin.

### [phobos/](./phobos)

This is an experimental nixos install inside a VM.

### [pluto/](./pluto)

This is my personal M2 Max MacBook, managed with nix-darwin and Home Manager.

### [polaris/](./polaris)

This is a _large_ bare-metal nixos server with dual rtx a6000s!

### [proteus/](./proteus)

This is a small nixos laptop!

### [styx/](./styx)

This is an M2 Ultra Mac Studio server managed with nix-darwin.

### [titan/](./titan)

This is a bare-metal nixos server with a modern dedicated GPU!

### [terra/](./terra)

This is one of my larger NixOS machines.

### [voyager/](./voyager/)

This is a NixOS install running on top of WSL2.

### [common.nix](./common.nix)

This file reduces duplication across NixOS configurations and contains common environment setup and services.

### [common_darwin.nix](./common_darwin.nix)

Shared defaults for nix-darwin machines.

### [constants.nix](./constants.nix)

Shared host names, ports, machine groups, and key material.
