# pluto

This is my personal M1 Pro Macbook, running MacOS and using nix-darwin and home-manager to manage things.

## setup

```bash
# ensure nix is installed, repo is cloned to ~/.config/nixpkgs

# export NIX_PATH, load into a shell
export NIX_PATH="darwin-config=/Users/$USER/.config/nixpkgs/hosts/m1max/configuration.nix:nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixpkgs:$NIX_PATH"
nix shell -f https://github.com/LnL7/nix-darwin/archive/master.tar.gz

# run initial install
darwin-installer

# rebuild
## grab this nix store path from above
darwin-rebuild switch -I darwin=/nix/store/3y5bvzx51dkrrsbdk2dhs9c6z4vlmjfa-nix-darwin -I darwin-config=/Users/$USER/.config/nixpkgs/hosts/m1max/configuration.nix
```

## manual tweaks

### max open files

```bash
curl https://raw.githubusercontent.com/jpetrucciani/nix/main/scripts/files/com.startup.sysctl.plist |
    sudo tee /Library/LaunchDaemons/com.startup.sysctl.plist
sudo chown root:wheel /Library/LaunchDaemons/com.startup.sysctl.plist
sudo launchctl load /Library/LaunchDaemons/com.startup.sysctl.plist
```

### touch id sudo

We probably want to be able to use touch id for sudo on iterm. There is now a [module here](../modules/pam.nix) which can help nix-darwin configure this for us.

### disable annoying message for brew installs

```bash
# before first switch
sudo spctl --master-disable

# after switch
sudo spctl --master-enable
```

### install rosetta2

```bash
/usr/sbin/softwareupdate --install-rosetta --agree-to-license
```

---

## [configuration.nix](./configuration.nix)

This file defines the OS configuration for the `pluto` machine.
