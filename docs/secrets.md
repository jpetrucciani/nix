# Secrets

Secrets are managed with `agenix` under `secrets/`. That means the repo can keep encrypted secret files in Git without committing plaintext values.

## Files

- encrypted material: `*.age`
- recipient mapping: `secrets/secrets.nix`

## Standard Flow

```bash
# edit existing encrypted secret
agenix -e secrets/<service>.age
```

## Add a New Secret

1. Create encrypted file with `agenix`.
2. Add recipients in `secrets/secrets.nix`.
3. Reference the secret from host config:

```nix
age.secrets.<service>.file = ../../secrets/<service>.age;
```

## Safety Rules

- never commit plaintext secrets.
- keep names service-oriented and lowercase.
- validate affected host builds before merge.

## Source

- `secrets/README.md`
- `secrets/secrets.nix`
