# edge

This is a large NixOS VM used for Blackedge internal services and tooling.

## bootstrap

```bash
# load nixos iso
# nixos-up
sudo nix-shell https://nix.cobi.dev/os-up

# generate ssh key, add to github
ssh-keygen -o -a 100 -t ed25519 -C "jacobi@edge"

# clone repo
nix-shell -p git
git clone git@github.com:jpetrucciani/nix.git ~/cfg
cd ~/cfg

# initial switch. after this, you can use just `hms` to update!
$(nix build --no-link --print-out-paths --extra-experimental-features nix-command --extra-experimental-features flakes ~/cfg#hmx.edge)/bin/switch
```

## updates

```bash
cd ~/cfg
hms

# explicit switch command if needed
$(nix build --no-link --print-out-paths --extra-experimental-features nix-command --extra-experimental-features flakes ~/cfg#hmx.edge)/bin/switch
```

## host-specific caveats

- caddy on this host expects TLS files at `/opt/crt/bec.crt` and `/opt/crt/bec.key`.
- the CIFS mount at `/mnt/win` expects credentials in `/etc/default/smb-secrets`.
- `conf.blackedge.enable = true` configures LDAP/AD login and expects bind secrets in `/etc/default/sssd`.
- this host intentionally has `networking.firewall.enable = false`.

---

## In this directory

### [configuration.nix](./configuration.nix)

This file defines the OS configuration for the `edge` machine.

### [hardware-configuration.nix](./hardware-configuration.nix)

This is an auto-generated file that configures disks and hardware settings for nixos.
