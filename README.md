# nix

[![uses nix](https://img.shields.io/badge/uses-nix-%237EBAE4)](https://nixos.org/)

_my nixpkgs setup and overlays_

## install

```bash
# install nix
## linux and mac
curl -L https://nixos.org/nix/install | sh

# configure nix
mkdir -p ~/.config/nix/
echo -e 'max-jobs = auto\ntarball-ttl = 0\nexperimental-features = nix-command flakes' >>~/.config/nix/nix.conf

# if multi-user install, add current user as trusted
echo "trusted-users = root $USER" | sudo tee -a /etc/nix/nix.conf && sudo pkill nix-daemon

# cachix (optional)
nix-env -iA nixpkgs.cachix
cachix use jacobi

# install home manager (if using it)
echo "export NIX_PATH=/nix/var/nix/profiles/per-user/$USER/channels:nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixpkgs:/nix/var/nix/profiles/per-user/root/channels" | sudo tee -a /etc/profile
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install

# pull repo into ~/.config/nixpkgs/
cd ~/.config/nixpkgs
rm home.nix

# read only
git clone https://github.com/jpetrucciani/nix.git .

# write access (requires a ssh key)
git clone git@github.com:jpetrucciani/nix.git .

# enable home-manager
home-manager switch
```

## In this repo

### [.github/](./.github/)

This directory contains my GitHub actions, which are used to automatically check for updates to various sources, and rebuild and cache my nix setups for multiple platforms.

### [hosts/](./hosts/)

This directory contains my NixOS configurations for each of my NixOS machines, as well as a `common.nix` file that contains shared configurations for all of my NixOS machines.

### [mods/](./mods/)

This directory contains my overlays for nixpkgs, but is set up in a way that others can reuse specific parts of my overlays if they'd like to use this repo as a source.

### [pkgs/](./pkgs/)

This directory contains nix packages that I've built that are not yet ready for nixpkgs proper, or that don't make sense to open as a PR to nixpkgs proper.

### [scripts/](./scripts/)

This directory contains various random scripts that I use in a few places in this repo, or in packages created by this repo.

### [sources/](./sources/)

This directory contains rev/sha256 combos for any of the other repos that I track and pin in this repo. These are automatically updated with GitHub actions!

### [default.nix](./default.nix)

This file acts as the entrypoint for nix to pin my nixpkgs version to the rev and sha256 found [in the sources directory](./sources/nixpkgs.json).

### [home.nix](./home.nix)

This file contains my main [home-manager](https://github.com/nix-community/home-manager) configuration. This includes all sorts of packages, configurations, and dotfiles for pretty much all software that I use.

### [overlays.nix](./overlays.nix)

This file declares the overlays that I apply to my pinned version of nixpkgs. This should load all of the files in the [mods](./mods/) directory, which are overlay functions which apply to my nixpkgs object in nix.
