# voyager

This is a nixos install running on top of wsl2!

## bootstrap

```bash
# generate ssh key, add to github
ssh-keygen -o -a 100 -t ed25519 -C "jacobi@voyager"

# clone repo
nix-shell -p git
git clone git@github.com:jpetrucciani/nix.git ~/cfg
cd ~/cfg

# initial switch. after this, you can use just `hms` to update!
$(nix build --no-link --print-out-paths --extra-experimental-features nix-command --extra-experimental-features flakes ~/cfg#hmx.voyager)/bin/switch
```

---

## In this directory

### [configuration.nix](./configuration.nix)

This file defines the OS configuration for the `voyager` wsl2 machine.
