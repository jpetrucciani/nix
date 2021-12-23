# pluto

This is my personal M1 Pro Macbook, running MacOS and using nix-darwin and home-manager to manage things.

## setup

```bash
# ensure nix is installed, repo is cloned to ~/.config/nixpkgs

# export NIX_PATH, load into a shell
export NIX_PATH="darwin-config=/Users/jacobi/.config/nixpkgs/hosts/pluto/configuration.nix:nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixpkgs:$NIX_PATH"
nix shell -f https://github.com/LnL7/nix-darwin/archive/master.tar.gz

# run initial install
darwin-installer

# rebuild
darwin-rebuild switch -I darwin=/nix/store/3y5bvzx51dkrrsbdk2dhs9c6z4vlmjfa-nix-darwin -I darwin-config=/Users/jacobi/.config/nixpkgs/hosts/pluto/configuration.nix
```

## manual tweaks

### touch id sudo

We probably want to be able to use touch id for sudo on iterm:

```bash
sudo nano /etc/pam.d/sudo

# place the following line at the top of this file
auth       sufficient     pam_tid.so
```

### install rosetta2

```bash
/usr/sbin/softwareupdate --install-rosetta --agree-to-license
```

---

## [configuration.nix](./configuration.nix)
