# andromeda

This is an experimental NixOS install inside a VM using the apple virtualization framework.

## bootstrap

```bash
# load nixos iso
# nixos-up
sudo nix-shell https://nix.cobi.dev/os-up

# generate ssh key, add to github
ssh-keygen -o -a 100 -t ed25519 -C "jacobi@andromeda"

# clone repo
nix-shell -p git
git clone git@github.com:jpetrucciani/nix.git ~/cfg
cd ~/cfg

# initial switch
export HOSTNAME='andromeda'
nix build -f . hms
./result/bin/hms
```

---

## In this directory

### [configuration.nix](./configuration.nix)

This file defines the OS configuration for the `andromeda` machine.

### [hardware-configuration.nix](./hardware-configuration.nix)

This is an auto-generated file by [nixos-up](https://github.com/samuela/nixos-up) that configures disks and other plugins for nixos.
