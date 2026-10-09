# Hermes Agent Sandboxes

The `hermes-agent.nix` module runs each Hermes Agent instance in a separate
rootless Podman container. This guide bootstraps an instance with credentials
stored in its private state directory. Agenix can be added later.

## Add an instance

For a host configuration under `hosts/<machine>/configuration.nix`:

```nix
{ pkgs, ... }:
{
  imports = [ ../modules/servers/hermes-agent.nix ];

  services.hermes-agent = {
    enable = true;
    instances.coder = {
      uid = 32001;
      packages = with pkgs; [
        gh
        git
        openssh
      ];
      settings = {
        terminal = {
          backend = "local";
          cwd = "/workspace";
          home_mode = "profile";
        };
        tool_loop_guardrails.hard_stop_enabled = true;
      };
      mounts."/workspace" = {
        source = "/srv/hermes/coder";
        readOnly = false;
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /srv/hermes/coder 0750 hermes-coder hermes-coder -"
  ];
}
```

Keep each instance's `uid` unique and stable. A writable mount must be owned by
the instance user or otherwise grant that user access through host permissions.
After rebuilding the host, start the gateway:

```bash
sudo systemctl start podman-hermes-agent-coder.service
sudo systemctl status podman-hermes-agent-coder.service
```

## Run the setup wizard

The module installs `hermes_podman`, which supplies the declared instance user,
home, and runtime directory needed to address the correct rootless Podman store.

Run Hermes' interactive setup inside the existing container, then restart the
gateway so it reloads the new configuration:

```bash
hermes_podman coder exec -it hermes-agent-coder hermes setup
# Or use Nous Portal OAuth:
hermes_podman coder exec -it hermes-agent-coder hermes setup --portal

sudo systemctl restart podman-hermes-agent-coder.service
```

The setup wizard writes non-secret settings to `config.yaml`, API keys to
`.env`, and OAuth credentials to `auth.json`. That matches Hermes' documented
[configuration layout](https://hermes-agent.nousresearch.com/docs/user-guide/configuration).

## Work inside the sandbox

Use the same helper for an interactive shell or one-off commands:

```bash
hermes_podman coder shell
hermes_podman coder exec -it hermes-agent-coder hermes config
hermes_podman coder exec -it hermes-agent-coder hermes config check
hermes_podman coder exec -it hermes-agent-coder hermes doctor
hermes_podman coder logs -f hermes-agent-coder
```

Inside the shell, CLI credentials remain independent because `HOME` is the
instance's persistent `/var/lib/hermes/home` directory:

```bash
ssh-keygen -t ed25519
gh auth login
```

To add a secret without putting its value in shell history:

```bash
read -rsp "OpenRouter key: " key; echo
hermes config set OPENROUTER_API_KEY "$key"
unset key
```

Hermes recognizes credential-shaped keys and saves them to `.env`; other values
go to `config.yaml`. MCP configuration can refer to those values as
`${env:OPENROUTER_API_KEY}`.

## Use the host Nix daemon

Goblin on `cy1-nix-01` includes `git`, `glab`, `openssh`, `uv`, and the same Nix
client as the host. It mounts `/nix/store` and `/nix/var/nix/daemon-socket`
read-only. `NIX_REMOTE=daemon` sends builds and downloads to the host daemon;
new store paths are immediately visible through the store mount. Mount the
socket directory so daemon restarts can replace the socket without leaving a
stale bind mount.

For another instance, set `enableNix = true` (it defaults to `false`):

```nix
{ pkgs, ... }:
{
  services.hermes-agent.instances.coder = {
    enableNix = true;
    packages = with pkgs; [
      git
      glab
      openssh
      uv
    ];
  };
}
```

The flag includes `config.nix.package`, sets `NIX_REMOTE`, `NIX_PATH`,
`NIX_CONFIG`, and `NIX_SSL_CERT_FILE`, and adds the read-only store and socket
directory mounts. Its flake registry pins `nixpkgs` to `pkgs.path` and includes
the host's `nix.registry` entries. The container service wants and starts after
`nix-daemon.socket`, with `/nix/store` in `RequiresMountsFor`. Instance
`environment` values can override the Nix environment defaults; the Nix mount
targets are managed by the module when the flag is enabled.

The module's mounts default to read-only. The container does not need the host
Nix database or writable access to the store. The daemon sees the instance's
host user, such as `hermes-goblin`, because Podman runs rootless. Ordinary builds
need an allowed daemon user; adding that user to `trusted-users` is unnecessary.
See the Nix manual for the [daemon store](https://nix.dev/manual/nix/2.32/store/types/local-daemon-store)
and [daemon access settings](https://nix.dev/manual/nix/2.32/command-ref/conf-file.html#conf-allowed-users).

After rebuilding `cy1-nix-01`, enter Goblin's shell to create its key, sign in to
GitLab, and check the daemon connection:

```bash
hermes_podman goblin shell
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519
glab auth login
nix store ping --store daemon
nix-shell -p jq --run 'jq --version'
```

The SSH key and CLI credentials persist in Goblin's private home on the host at
`/var/lib/hermes-agent/goblin/hermes/home`.

## Know where state lives

| Purpose                 | Inside the container          | On the host                                      |
| ----------------------- | ----------------------------- | ------------------------------------------------ |
| Hermes settings         | `/var/lib/hermes/config.yaml` | `/var/lib/hermes-agent/coder/hermes/config.yaml` |
| API keys and tokens     | `/var/lib/hermes/.env`        | `/var/lib/hermes-agent/coder/hermes/.env`        |
| OAuth credentials       | `/var/lib/hermes/auth.json`   | `/var/lib/hermes-agent/coder/hermes/auth.json`   |
| SSH and CLI state       | `/var/lib/hermes/home`        | `/var/lib/hermes-agent/coder/hermes/home`        |
| Rootless Podman storage | not mounted in the container  | `/var/lib/hermes-agent/coder/podman`             |

Skipping Agenix means `.env` and `auth.json` are plaintext on the host, although
the module makes the instance state directory private to its system user. Do not
commit either file. You can also place an `.env` file directly at the host path
above, provided it remains owned by `hermes-coder` and mode `0600`.

The module's `settings` option is different: it renders an immutable managed
`/etc/hermes/config.yaml`. Managed keys override the writable `config.yaml`, so
only put values there that the setup wizard should not change. See Hermes'
[managed-scope rules](https://hermes-agent.nousresearch.com/docs/user-guide/managed-scope)
for the precedence details.

When you are ready to move secrets to Agenix, configure the instance's
`environmentFiles` and remove the duplicate values from its writable `.env`.
The full example is in the
[module README](https://github.com/jpetrucciani/nix/blob/main/hosts/modules/servers/README.md).
