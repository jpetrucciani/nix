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

# initial switch
export HOSTNAME='neptune'
$(nix-build --no-link --expr 'with import ~/cfg {}; _nixos-switch' --argstr host "$HOSTNAME")/bin/switch
```

---

## In this directory

### [api.nix](./api.nix)

This file defines the api systemd service

### [configuration.nix](./configuration.nix)

This file defines the OS configuration for the `neptune` machine.

### [hardware-configuration.nix](./hardware-configuration.nix)

This is an auto-generated file by the nixos install process that configures disks and other plugins for nixos.
