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

Podman storage belongs to the instance's system user. This shell helper supplies
the user, home, and runtime directory needed to address the correct rootless
Podman store:

```bash
hermes_podman() {
  sudo -u hermes-coder env \
    HOME=/var/lib/hermes-agent/coder/podman \
    XDG_RUNTIME_DIR=/run/user/32001 \
    /run/current-system/sw/bin/podman "$@"
}
```

Run Hermes' interactive setup inside the existing container, then restart the
gateway so it reloads the new configuration:

```bash
hermes_podman exec -it hermes-agent-coder hermes setup
# Or use Nous Portal OAuth:
hermes_podman exec -it hermes-agent-coder hermes setup --portal

sudo systemctl restart podman-hermes-agent-coder.service
```

The setup wizard writes non-secret settings to `config.yaml`, API keys to
`.env`, and OAuth credentials to `auth.json`. That matches Hermes' documented
[configuration layout](https://hermes-agent.nousresearch.com/docs/user-guide/configuration).

## Work inside the sandbox

Use the same helper for an interactive shell or one-off commands:

```bash
hermes_podman exec -it hermes-agent-coder bash
hermes_podman exec -it hermes-agent-coder hermes config
hermes_podman exec -it hermes-agent-coder hermes config check
hermes_podman exec -it hermes-agent-coder hermes doctor
hermes_podman logs -f hermes-agent-coder
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
