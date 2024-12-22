# nyx0

This is a m4 mac mini

## setup

```bash
# ensure nix is installed, repo is cloned to ~/cfg
# initial switch. after this, you can use just `hms` to update!
$(nix build --no-link --print-out-paths --extra-experimental-features nix-command --extra-experimental-features flakes ~/cfg#hmx.nyx0)/bin/switch
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

This file defines the OS configuration for the `nyx0` machine.
