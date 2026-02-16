# secrets

this directory contains encrypted secrets that use [agenix](https://github.com/ryantm/agenix)!

---

## workflow

### edit an existing secret

```bash
agenix -e secrets/miniflux.age
```

### add a new secret

1. Create/edit the encrypted file with agenix:

```bash
agenix -e secrets/<service>.age
```

2. Add recipient mapping in [`secrets.nix`](./secrets.nix).
3. Reference the secret from a host/module config:

```nix
age.secrets.<service>.file = ../../secrets/<service>.age;
```

## file naming rules

- use lowercase service-oriented names like `<service>.age`.
- keep one secret domain per file when practical.
- never commit plaintext secrets.

## safe update checklist

1. Ensure recipient keys in [`secrets.nix`](./secrets.nix) include every host/user that needs decryption.
2. Re-encrypt with agenix, do not edit encrypted files manually.
3. Run a targeted build for affected hosts before merging.

```bash
nix build .#nixosConfigurations.terra.config.system.build.toplevel
```

## In this directory

### [authelia.age](./authelia.age)

agenix-encrypted secret material for authelia.

### [miniflux.age](./miniflux.age)

agenix-encrypted secret material for miniflux.

### [ntfy.age](./ntfy.age)

agenix-encrypted secret material for ntfy.

### [vaultwarden.age](./vaultwarden.age)

agenix-encrypted secret material for vaultwarden.

### [zitadel.age](./zitadel.age)

agenix-encrypted secret material for zitadel.

### [secrets.nix](./secrets.nix)

agenix mapping file that defines recipients for each encrypted secret.
