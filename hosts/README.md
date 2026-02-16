# hosts

This directory contains my nixos configurations for each of my nixos machines, as well as a `common.nix` file that contains shared configurations for all of my nixos machines.

---

## In this directory

### [edge/](./edge/)

this is a big vm

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

### [nyx0/](./nyx0)

This is a m4 mac mini

### [phobos/](./phobos)

This is an experimental nixos install inside a VM.

### [pluto/](./pluto)

This is my personal M2 Max Macbook, running MacOS and using nix-darwin and home-manager to manage things.

### [polaris/](./polaris)

This is a _large_ bare-metal nixos server with dual rtx a6000s!

### [styx/](./styx)

This is a M2 Ultra Mac Studio server

### [titan/](./titan)

This is a bare-metal nixos server with a modern dedicated GPU!

### [terra/](./terra)

This is my second largest nixos based machine

### [voyager/](./voyager/)

This is a nixos install running on top of wsl2!

### [common.nix](./common.nix)

This file serves as a nice way to reduce duplication across nixos configurations. It contains all my common env setup and services.

### [common_darwin.nix](./common_darwin.nix)

shared values for darwin boxes

### [constants.nix](./constants.nix)

shared values for more than just me!
