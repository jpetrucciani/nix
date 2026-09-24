# Secrets

Secrets are managed with `agenix` under `secrets/`. That means the repo can keep encrypted secret files in Git without committing plaintext values.

## Files

- encrypted material: `*.age`
- recipient mapping: `secrets/secrets.nix`

## Standard Flow

From the repository root, edit an existing secret with the rules file in scope:

```bash
(cd secrets && agenix -e miniflux.age)
```

## Add a New Secret

1. Add the new filename and its recipient keys to `secrets/secrets.nix`.
2. From the repository root, create the encrypted file with `(cd secrets && agenix -e service-name.age)`, replacing
   `service-name` with the real name. Agenix reads `secrets.nix` from its working directory.
3. Reference the secret from the affected host or module. For example, in `hosts/<name>/configuration.nix`:

```nix
age.secrets.miniflux.file = ../../secrets/miniflux.age;
```

## Safety Rules

- never commit plaintext secrets.
- keep names service-oriented and lowercase.
- validate affected host builds before merge.

## Source

- `secrets/README.md`
- `secrets/secrets.nix`
