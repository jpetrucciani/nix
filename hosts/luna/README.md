# luna

This is a bare-metal physical nixos server!

## bootstrap

```bash
# load nixos iso
# nixos-up
sudo nix-shell https://nix.cobi.dev/os-up

# generate ssh key, add to github
ssh-keygen -o -a 100 -t ed25519 -C "jacobi@luna"

# clone repo
nix-shell -p git
git clone git@github.com:jpetrucciani/nix.git ~/cfg
cd ~/cfg

# initial switch
export HOSTNAME='luna'
nix build --extra-experimental-features nix-command -f . hms
./result/bin/hms
```

---

## In this directory

### [configuration.nix](./configuration.nix)

This file defines the OS configuration for the `luna` machine.

### [hardware-configuration.nix](./hardware-configuration.nix)

This is an auto-generated file that configures disks and other plugins for nixos.
