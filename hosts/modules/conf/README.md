# conf

configuration modules shared by host configs.

## usage

Import the module in a host's `configuration.nix`, then set the matching options.

```nix
imports = [
  ../modules/conf/blackedge.nix
  ../modules/conf/ssh-remote-bind.nix
];
```

---

## In this directory

### [blackedge.nix](./blackedge.nix)

Adds Blackedge-focused auth and access config, including SSSD, Kerberos, LDAP, and related ssh/sudo policies.

### [ssh-remote-bind.nix](./ssh-remote-bind.nix)

Provides a persistent reverse-ssh systemd service via `services.ssh-remote-bind.*` options.
