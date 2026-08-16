# servers

This directory contains misc servers implemented as nix modules!

---

## In this directory

### [ace-step.nix](./ace-step.nix)

A GPU-backed NixOS service for the [ACE-Step](https://github.com/ace-step/ACE-Step-1.5) music generation API.

The module keeps checkpoints and generated output under `/var/lib/ace-step`, uses a separate writable cache, and can
download the bundled model before starting the API. GPU visibility, eager loading, and the language-model planner are
configurable:

```nix
{
  imports = [ ../modules/servers/ace-step.nix ];

  services.ace-step = {
    enable = true;
    address = "0.0.0.0";
    port = 8012;
    gpuDevice = "0";
    languageModel = {
      enable = true;
      model = "acestep-5Hz-lm-1.7B";
      backend = "vllm";
    };
  };
}
```

### [goto.nix](./goto.nix)

a service to run + watch a local executable

### [hermes-agent.nix](./hermes-agent.nix)

Multi-instance Hermes Agent service with per-agent rootless Podman sandboxes

Each instance has its own host user, Podman storage, Hermes state, CLI home,
secret environment, package set, network, and bind-mount allowlist. The
container runs Hermes' `local` terminal backend inside the outer Podman sandbox.

See the [bootstrap guide](../../../docs/hermes-agent.md) for initial setup,
plain-state credentials, and running commands inside a container.

```nix
{ config, pkgs, ... }:
{
  imports = [ ../modules/servers/hermes-agent.nix ];

  age.secrets = {
    hermes-coder-env = {
      file = ./secrets/hermes-coder-env.age;
      owner = "hermes-coder";
      group = "hermes-coder";
      mode = "0400";
    };
    hermes-coder-ssh = {
      file = ./secrets/hermes-coder-ssh.age;
      owner = "hermes-coder";
      group = "hermes-coder";
      mode = "0400";
    };
    hermes-research-env = {
      file = ./secrets/hermes-research-env.age;
      owner = "hermes-research";
      group = "hermes-research";
      mode = "0400";
    };
  };

  services.hermes-agent = {
    enable = true;
    instances = {
      coder = {
        uid = 32001;
        packages = with pkgs; [
          gh
          github-mcp-server
          openssh
        ];
        environmentFiles = [ config.age.secrets.hermes-coder-env.path ];
        settings = {
          terminal = {
            backend = "local";
            cwd = "/workspace/cfg";
            env_passthrough = [ "GITHUB_TOKEN" ];
          };
          mcp_servers.github = {
            command = "github-mcp-server";
            args = [ "stdio" ];
            env.GITHUB_PERSONAL_ACCESS_TOKEN = "\${env:GITHUB_TOKEN}";
          };
          tool_loop_guardrails.hard_stop_enabled = true;
        };
        mounts = {
          "/workspace/cfg" = {
            source = "/srv/hermes/coder-workspace";
            readOnly = false;
          };
          "/var/lib/hermes/home/.ssh/id_ed25519" = {
            source = config.age.secrets.hermes-coder-ssh.path;
          };
        };
        cpus = "2";
        memory = "4g";
      };

      research = {
        uid = 32002;
        environmentFiles = [ config.age.secrets.hermes-research-env.path ];
        mounts."/research".source = "/srv/research";
      };
    };
  };
}
```

Secret environment files use Podman's `KEY=value` format. They are read at
service start and must be readable by the instance user. Keep MCP secrets in the
environment file, then reference them from `settings.mcp_servers.<name>.env` as
shown above so Hermes' MCP environment filter passes only the intended values.
Host filesystem permissions still apply to bind mounts. Make writable workspace
directories owned by the instance user/group, or grant access through
`supplementaryGroups`; the module deliberately does not chown arbitrary mounts.

### [infinity.nix](./infinity.nix)

[infinity](https://github.com/michaelfeil/infinity) embeddings server

### [minifluxng.nix](./minifluxng.nix)

miniflux

### [obligator.nix](./obligator.nix)

[obligator](https://github.com/lastlogin-net/obligator) service

### [poglets.nix](./poglets.nix)

This NixOS module contains a service for [poglets](https://github.com/jpetrucciani/poglets)

### [questdb.nix](./questdb.nix)

nixos module for [questdb](https://github.com/questdb/questdb)

### [proxysql.nix](./proxysql.nix)

nixos module for [proxysql](https://github.com/sysown/proxysql)

### [semaphore.nix](./semaphore.nix)

NixOS module for [Semaphore UI](https://github.com/semaphoreui/semaphore)

### [titanite.nix](./titanite.nix)

NixOS module for the Titanite DNS resolver

### [zinc.nix](./zinc.nix)

This NixOS module contains a service for [zinc](https://github.com/zinclabs/zincsearch)
