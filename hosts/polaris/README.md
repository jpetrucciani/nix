# polaris

This is a _large_ bare-metal nixos server with dual rtx a6000s!

## bootstrap

```bash
# load nixos iso
# nixos-up
sudo nix-shell https://nix.cobi.dev/os-up

# generate ssh key, add to github
ssh-keygen -o -a 100 -t ed25519 -C "jacobi@polaris"

# zfs
wipefs -a /dev/nvme1n1  # extra drive in the nvme riser
sudo zpool create -o ashift=12 -o autotrim=on zroot /dev/nvme1n1
sudo zfs create zroot/box
sudo zfs set compression=lz4 zroot/box
sudo zfs set atime=off zroot/box
sudo zfs set recordsize=128k zroot/box
sudo zfs set mountpoint=/opt/box zroot/box

# clone repo
nix-shell -p git
git clone git@github.com:jpetrucciani/nix.git ~/cfg
cd ~/cfg

# initial switch. after this, you can use just `hms` to update!
$(nix build --no-link --print-out-paths --extra-experimental-features nix-command --extra-experimental-features flakes ~/cfg#hmx.polaris)/bin/switch
```

---

## In this directory

### [configuration.nix](./configuration.nix)

This file defines the OS configuration for the `polaris` machine.

### [hardware-configuration.nix](./hardware-configuration.nix)

This is an auto-generated file by [nixos-up](https://github.com/samuela/nixos-up) that configures disks and other plugins for nixos.
