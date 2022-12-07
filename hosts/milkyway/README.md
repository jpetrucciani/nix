# milkyway

This is a nixos install running on top of wsl2!

## bootstrap

```bash
# load nixos iso
# nixos-up
sudo nix-shell https://nix.cobi.dev/os-up

# generate ssh key, add to github
ssh-keygen -o -a 100 -t ed25519 -C "jacobi@milkyway"

# clone repo
nix-shell -p git
git clone git@github.com:jpetrucciani/nix.git ~/cfg
cd ~/cfg

# initial switch
export HOSTNAME='milkyway'
nix build -f . hms
./result/bin/hms
```

---

## In this directory

### [configuration.nix](./configuration.nix)

This file defines the OS configuration for the `milkyway` wsl2 machine.
