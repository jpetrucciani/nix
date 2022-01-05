# hosts

This directory contains my NixOS configurations for each of my NixOS machines, as well as a `common.nix` file that contains shared configurations for all of my NixOS machines.

---

## In this directory

### [hyperion/](./hyperion)

This is an experimental NixOS install inside a VM.

### [m1max/](./m1max)

This is my m1 max Macbook Pro laptop

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

### [work/](./work)

This is a NixOS install inside a VM for work.

### [common.nix](./common.nix)

This file serves as a nice way to reduce duplication across NixOS configurations. It contains all my common env setup and services.
