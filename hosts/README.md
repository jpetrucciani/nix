# hosts

This directory contains my NixOS configurations for each of my NixOS machines, as well as a `common.nix` file that contains shared configurations for all of my NixOS machines.

---

## In this directory

### [andromeda/](./andromeda)

This is an experimental NixOS install inside a VM using the apple virtualization framework.

### [charon/](./charon)

This is my personal M1 Mac Mini server, running MacOS and using nix-darwin and home-manager to manage things.

### [foundry/](./foundry/)

this directory contains builders for cloud VM images and isos

### [hyperion/](./hyperion)

This is an experimental NixOS install inside a VM.

### [luna/](./luna)

This is a bare-metal physical nixos server!

### [m1max/](./m1max)

This is my work M1 Max Macbook, running MacOS and using nix-darwin and home-manager to manage things.

### [milkyway/](./milkyway/)

This is a nixos install running on top of wsl2!

### [modules/](./modules)

additional modules for use in the various host configurations for nixos and nix-darwin machines.

### [neptune/](./neptune)

This is a bare-metal server.

### [pluto/](./pluto)

This is my personal M1 Pro Macbook, running MacOS and using nix-darwin and home-manager to manage things.

### [tethys/](./tethys)

This is an experimental NixOS install inside a VM.

### [titan/](./titan)

This is an experimental NixOS install inside a VM.

### [common.nix](./common.nix)

This file serves as a nice way to reduce duplication across NixOS configurations. It contains all my common env setup and services.
