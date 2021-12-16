# hosts

This directory contains my NixOS configurations for each of my NixOS machines, as well as a `common.nix` file that contains shared configurations for all of my NixOS machines.

---

## [hyperion/](./hyperion)

This is an experimental NixOS install inside a VM.

## [neptune/](./neptune)

This is a bare-metal server.

## [pluto/](./pluto)

This is my personal M1 Pro Macbook, running MacOS and using nix-darwin and home-manager to manage things.

## [tethys/](./tethys)

This is an experimental NixOS install inside a VM.

## [titan/](./titan)

This is an experimental NixOS install inside a VM.

## [common.nix](./common.nix)

This file serves as a nice way to reduce duplication across NixOS configurations. It contains all my common env setup and services.
