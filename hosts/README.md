# hosts

This directory contains my nixos configurations for each of my nixos machines, as well as a `common.nix` file that contains shared configurations for all of my nixos machines.

---

## In this directory

### [andromeda/](./andromeda)

This is an experimental nixos install inside a VM using the apple virtualization framework.

### [charon/](./charon)

This is my personal M1 Mac Mini server, running MacOS and using nix-darwin and home-manager to manage things.

### [foundry/](./foundry/)

this directory contains builders for cloud VM images and isos

### [luna/](./luna)

This is a bare-metal physical nixos server!

### [m1max/](./m1max)

This is my work M1 Max Macbook, running MacOS and using nix-darwin and home-manager to manage things.

### [milkyway/](./milkyway/)

This is a nixos install running on top of wsl2!

### [modules/](./modules)

additional modules for use in the various host configurations for nixos and nix-darwin machines.

### [neptune/](./neptune)

This is a bare-metal nixos server.

### [phobos/](./phobos)

This is an experimental nixos install inside a VM.

### [pluto/](./pluto)

This is my personal M2 Max Macbook, running MacOS and using nix-darwin and home-manager to manage things.

### [styx/](./styx)

This is a M2 Ultra Mac Studio server

### [titan/](./titan)

This is a bare-metal nixos server with a modern dedicated GPU!

### [terra/](./terra)

This is my second largest nixos based machine

### [common.nix](./common.nix)

This file serves as a nice way to reduce duplication across nixos configurations. It contains all my common env setup and services.
