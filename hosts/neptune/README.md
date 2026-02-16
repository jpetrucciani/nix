# neptune

This is a bare-metal server running nixos.

## bootstrap

[This a special bare-metal server running on Hetzner](https://nixos.wiki/wiki/Install_NixOS_on_Hetzner_Online).

```bash
# generate ssh key, add to github
ssh-keygen -o -a 100 -t ed25519 -C "jacobi@neptune"

# TODO
# add our user, add to wheel group, add nix.conf to our user conf dir

# clone repo
nix-shell -p git
git clone git@github.com:jpetrucciani/nix.git ~/cfg
cd ~/cfg

# initial switch. after this, you can use just `hms` to update!
$(nix build --no-link --print-out-paths --extra-experimental-features nix-command --extra-experimental-features flakes ~/cfg#hmx.neptune)/bin/switch
```

---

## In this directory

### [configuration.nix](./configuration.nix)

This file defines the OS configuration for the `neptune` machine.

### [hardware-configuration.nix](./hardware-configuration.nix)

This is an auto-generated file by the nixos install process that configures disks and other plugins for nixos.
