# m1max

This is my work M1 Max Macbook, running MacOS and using nix-darwin and home-manager to manage things.

## setup

```bash
# ensure nix is installed, repo is cloned to ~/cfg
$(nix-build --no-link --expr 'with import ~/cfg {}; _nix-darwin-switch' --argstr host m1max)/bin/switch

```

## manual tweaks

### max open files

```bash
curl https://raw.githubusercontent.com/jpetrucciani/nix/main/scripts/files/com.startup.sysctl.plist |
    sudo tee /Library/LaunchDaemons/com.startup.sysctl.plist
sudo chown root:wheel /Library/LaunchDaemons/com.startup.sysctl.plist
sudo launchctl load /Library/LaunchDaemons/com.startup.sysctl.plist
```

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

## In this directory

### [configuration.nix](./configuration.nix)

This file defines the OS configuration for the `m1max` machine.
