# services.buzz-agents: Buzz ACP agents as podman containers.
#
# - One fleet definition shared by every host (colmena `defaults`); each host
#   only instantiates agents whose `host` matches its networking.hostName.
# - Each agent: own host uid, own persistent home (/var/lib/buzz-agents/<name>
#   -> /home/agent), agenix secrets decrypted into ~/.secrets, own GitHub identity.
# - Containers mount the host /nix/store read-only and talk to the host
#   nix-daemon, so agents get their Nix-built profile plus full `nix` usage.
# - Requires the agenix NixOS module.
{ config
, lib
, pkgs
, ...
}:
let
  inherit (lib)
    mkOption
    mkEnableOption
    mkIf
    mkMerge
    types
    literalExpression
    filterAttrs
    mapAttrsToList
    attrValues
    concatStringsSep
    concatMapStrings
    optionalString
    optionalAttrs
    escapeShellArg
    hiPrio
    ;

  cfg = config.services.buzz-agents;
  home = "/home/agent";

  enabledAgents = filterAttrs (_: a: a.enable) cfg.agents;
  localAgents = filterAttrs (_: a: a.host == config.networking.hostName) enabledAgents;

  # Idempotent installs into persistent prefixes, for runtimes not in nixpkgs.
  # Re-runs only when the argument list changes (or you delete the stamp).
  stampOf = args: builtins.substring 0 12 (builtins.hashString "sha256" (toString args));
  npmGlobal = args: ''
    if [ ! -e "$NPM_CONFIG_PREFIX/.stamp-${stampOf args}" ]; then
      npm install -g --no-fund --no-audit ${toString args}
      touch "$NPM_CONFIG_PREFIX/.stamp-${stampOf args}"
    fi
  '';

  # Runtime presets, mirroring Buzz Desktop's harness catalog.
  runtimes = {
    buzz-agent = {
      command = "buzz-agent";
      args = [ ];
      packages = [ ];
      bootstrap = "";
    };
    goose = {
      command = "goose";
      args = [ "acp" ];
      packages = [ pkgs.goose-cli ];
      bootstrap = "";
    };
    claude = {
      command = "claude-agent-acp";
      args = [ ];
      packages = [ pkgs.claude-agent-acp pkgs.claude-code ];
      bootstrap = "";
    };
    codex = {
      command = "codex-acp";
      args = [ ];
      packages = [ pkgs.codex-acp pkgs.codex-latest ];
      bootstrap = "";
    };
    opencode = {
      command = "opencode";
      args = [ "acp" ];
      packages = [ pkgs.opencode ];
      bootstrap = "";
    };
    # Buzz uses its own fork of the pi ACP adapter (pinned commit from Buzz's catalog).
    pi = {
      command = "buzz-pi-acp";
      args = [ ];
      packages = [ pkgs.pi-coding-agent pkgs.nodejs_22 ];
      bootstrap = npmGlobal [
        "--install-links=true"
        "'git+https://github.com/salman1993/buzz-pi-acp.git#86b201e'"
      ];
    };
    # Not in nixpkgs yet: only in my overlays
    kimi = {
      command = "kimi";
      args = [ "acp" ];
      packages = [ pkgs.uv pkgs.python3 pkgs.kimi-code ];
      bootstrap = "";
    };
    # Not in nixpkgs yet: supply an install step via `bootstrap` on the agent.
    hermes = {
      command = "hermes-acp";
      args = [ ];
      packages = [ pkgs.uv pkgs.python3 ];
      bootstrap = "";
    };
  };

  # GitHub's published host keys (api.github.com/meta).
  knownHosts = pkgs.writeText "buzz-agents-known-hosts" ''
    github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
    github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
    ${cfg.extraKnownHosts}
  '';

  # `nixpkgs#foo` inside agents resolves to the host's nixpkgs (already mostly in the store).
  flakeRegistry = pkgs.writeText "buzz-agents-registry.json" (
    builtins.toJSON {
      version = 2;
      flakes = [
        {
          from = {
            type = "indirect";
            id = "nixpkgs";
          };
          to = {
            type = "path";
            path = "${cfg.nix.nixpkgs}";
          };
        }
      ];
    }
  );

  # MCP servers: a template with environment placeholders, rendered at container start
  # (envsubst) so bearer tokens come from the agenix env files.
  mcpTemplate = pkgs.writeText "buzz-agents-mcp.json" (
    builtins.toJSON {
      mcpServers = lib.mapAttrs
        (_: s: {
          type = s.transport;
          inherit (s) url headers;
        })
        cfg.mcpServers;
    }
  );
  mcpBridge = pkgs.writeShellScript "mcp-bridge" ''
    export BUZZ_MCP_CONFIG=${home}/.config/buzz-agents/mcp.json
    exec ${cfg.mcpBridge}
  '';

  # Minimal root: everything real comes from the bind-mounted host store.
  # Symlink targets are kept alive by references from each agent's unit.
  ldTarget =
    if pkgs.stdenv.hostPlatform.isx86_64 then
      "lib64/ld-linux-x86-64.so.2"
    else
      "lib/ld-linux-aarch64.so.1";
  baseImage = pkgs.dockerTools.buildImage {
    name = "buzz-agent-base";
    tag = "nix";
    extraCommands = ''
      mkdir -p bin usr/bin etc/ssl/certs tmp home/agent nix/store nix/var/nix/daemon-socket lib64 lib
      chmod 1777 tmp
      touch etc/passwd etc/group
      ln -s ${pkgs.bashInteractive}/bin/bash bin/sh
      ln -s ${pkgs.coreutils}/bin/env usr/bin/env
      ln -s ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt etc/ssl/certs/ca-certificates.crt
      ${optionalString cfg.fhsCompat "ln -s ${pkgs.nix-ld}/libexec/nix-ld ${ldTarget}"}
    '';
  };

  secretKeys = [
    "nsec"
    "authTag"
    "githubToken"
    "sshKey"
    "env"
  ];

  agentModule =
    { name, config, ... }:
    let
      preset = runtimes.${config.runtime} or null;
      conventional = key: cfg.secretsDir + "/${name}/${key}.age";
    in
    {
      options = {
        enable = mkOption {
          type = types.bool;
          default = true;
        };
        host = mkOption {
          type = types.str;
          description = "networking.hostName of the host that runs this agent. Never run one key on two hosts.";
        };
        uid = mkOption {
          type = types.ints.positive;
          description = "Host uid; also the identity the nix-daemon sees.";
        };
        pubkey = mkOption {
          type = types.strMatching "[0-9a-f]{64}";
          description = "Agent's Nostr pubkey (hex, public). Used for relay membership.";
        };
        displayName = mkOption {
          type = types.str;
          default = name;
        };

        runtime = mkOption {
          type = types.enum (builtins.attrNames runtimes ++ [ "custom" ]);
          default = "claude";
        };
        command = mkOption {
          type = types.str;
          default = if preset != null then preset.command else "";
          defaultText = literalExpression "runtime preset command";
        };
        args = mkOption {
          type = types.listOf types.str;
          default = if preset != null then preset.args else [ ];
        };
        model = mkOption {
          type = types.nullOr types.str;
          default = null;
        };
        effort = mkOption {
          type = types.nullOr types.str;
          default = null;
        };

        packages = mkOption {
          type = types.listOf types.package;
          default = [ ];
          description = "Extra packages on this agent's global PATH.";
        };
        bootstrap = mkOption {
          type = types.lines;
          default = "";
          description = "Idempotent shell run at every start, before buzz-acp (installs into ~/.local).";
        };

        persona = mkOption {
          type = types.lines;
          default = "";
          description = "Per-agent system prompt (becomes <agent-instructions>).";
        };
        respondTo = mkOption {
          type = types.enum [
            "owner-only"
            "allowlist"
            "anyone"
            "nobody"
          ];
          default = "owner-only";
        };
        respondToAllowlist = mkOption {
          type = types.listOf types.str;
          default = [ ];
        };
        sessionPolicy = mkOption {
          type = types.str;
          default = "thread";
          description = "`thread`: one ACP session per thread; `channel`: one per channel.";
        };
        parallelism = mkOption {
          type = types.ints.between 1 32;
          default = 1;
        };
        heartbeat = {
          interval = mkOption {
            type = types.int;
            default = 0;
            description = "Seconds; 0 disables, otherwise >= 10.";
          };
          prompt = mkOption {
            type = types.nullOr types.lines;
            default = null;
          };
        };

        github = {
          user = mkOption { type = types.str; };
          email = mkOption {
            type = types.str;
            description = "A verified email on the machine account (or its noreply address).";
          };
          signCommits = mkOption {
            type = types.bool;
            default = true;
            description = "SSH-sign commits with sshKey. Add the key to the account as a Signing key too.";
          };
          overrideGitIdentity = mkOption {
            type = types.bool;
            default = true;
            description = ''
              buzz-acp injects a Nostr git identity (npub author, x509 signing via
              git-sign-nostr) through GIT_CONFIG_COUNT. A `git` wrapper passing
              `-c` flags (which take precedence) replaces it with the GitHub identity.
              Disable if agents mainly commit to Buzz-hosted repos.
            '';
          };
        };

        secrets = lib.genAttrs secretKeys (
          key:
          mkOption {
            type = types.nullOr types.path;
            default =
              let
                p = conventional key;
              in
              if key == "env" && !builtins.pathExists p then null else p;
            defaultText = literalExpression ''cfg.secretsDir + "/<name>/${key}.age"'';
          }
        );

        environment = mkOption {
          type = types.attrsOf types.str;
          default = { };
        };
        resources = {
          memory = mkOption {
            type = types.nullOr types.str;
            default = "16g";
          };
          cpus = mkOption {
            type = types.nullOr types.str;
            default = null;
          };
          pids = mkOption {
            type = types.ints.positive;
            default = 8192;
          };
        };
        extraOptions = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Extra podman run flags (e.g. --network).";
        };
      };
    };

  mkAgent =
    name: a:
    let
      user = "buzz-agent-${name}";
      dir = "${cfg.stateDir}/${name}";
      preset = runtimes.${a.runtime} or {
        packages = [ ];
        bootstrap = "";
      };
      secretFiles = filterAttrs (_: v: v != null) (
        a.secrets // { sharedEnv = cfg.sharedEnvSecret; }
      );
      secretPath = key: "${home}/.secrets/${key}";

      gitWrapper = pkgs.writeShellScriptBin "git" ''
        exec ${pkgs.git}/bin/git \
          -c user.name=${escapeShellArg a.github.user} \
          -c user.email=${escapeShellArg a.github.email} \
          -c credential.https://github.com.helper= \
          -c 'credential.https://github.com.helper=!${pkgs.gh}/bin/gh auth git-credential' \
          ${
            if a.github.signCommits then
              "-c gpg.format=ssh -c user.signingkey=${secretPath "sshKey"} -c gpg.ssh.program=${pkgs.openssh}/bin/ssh-keygen -c commit.gpgSign=true -c tag.gpgSign=true"
            else
              "-c commit.gpgSign=false -c tag.gpgSign=false"
          } \
          "$@"
      '';

      profile = pkgs.buildEnv {
        name = "${user}-profile";
        paths =
          lib.optional a.github.overrideGitIdentity (hiPrio gitWrapper)
          ++ [ cfg.package ]
          ++ cfg.basePackages
          ++ preset.packages
          ++ a.packages
          ++ lib.optional (cfg.mcpServers != { }) pkgs.gettext;
      };

      passwd = pkgs.writeText "${user}-passwd" ''
        root:x:0:0::/root:/bin/sh
        agent:x:${toString a.uid}:${toString cfg.gid}:${a.displayName}:${home}:${pkgs.bashInteractive}/bin/bash
      '';
      group = pkgs.writeText "${user}-group" ''
        root:x:0:
        ${cfg.group}:x:${toString cfg.gid}:agent
      '';

      personaFile = pkgs.writeText "${user}-persona.md" a.persona;
      heartbeatFile = pkgs.writeText "${user}-heartbeat.md" (toString a.heartbeat.prompt);

      entrypoint = pkgs.writeShellScript "${user}-entrypoint" ''
        set -euo pipefail
        S=${home}/.secrets

        BUZZ_PRIVATE_KEY="$(<"$S/nsec")";     export BUZZ_PRIVATE_KEY
        BUZZ_AUTH_TAG="$(<"$S/authTag")";     export BUZZ_AUTH_TAG
        GH_TOKEN="$(<"$S/githubToken")";      export GH_TOKEN
        set -a
        [ -r "$S/sharedEnv" ] && . "$S/sharedEnv"
        [ -r "$S/env" ] && . "$S/env"
        set +a

        mkdir -p ${home}/work ${home}/.local/bin "$NPM_CONFIG_PREFIX" "$UV_TOOL_DIR" \
          ${home}/.config/buzz-agents ${home}/.ssh
        chmod 700 ${home}/.ssh

        ${optionalString (cfg.mcpServers != { }) ''
          (umask 077; envsubst < ${mcpTemplate} > ${home}/.config/buzz-agents/mcp.json)
        ''}

        # --- runtime bootstrap ---
        ${preset.bootstrap}
        # --- agent bootstrap ---
        ${a.bootstrap}

        cd ${home}/work
        exec buzz-acp
      '';

      environment = filterAttrs (_: v: v != null) (
        {
          HOME = home;
          USER = "agent";
          SHELL = "${pkgs.bashInteractive}/bin/bash";
          LANG = "C.UTF-8";
          TERM = "xterm-256color";
          PATH = concatStringsSep ":" [
            "${home}/.local/bin"
            "${home}/.local/npm/bin"
            "${home}/.nix-profile/bin"
            "${profile}/bin"
          ];
          SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          NPM_CONFIG_PREFIX = "${home}/.local/npm";
          UV_TOOL_DIR = "${home}/.local/share/uv/tools";
          UV_TOOL_BIN_DIR = "${home}/.local/bin";
          UV_PYTHON_DOWNLOADS = "never";
          GIT_SSH_COMMAND = if a.secrets.sshKey == null then null else "ssh -i ${secretPath "sshKey"} -o IdentitiesOnly=yes -o 'UserKnownHostsFile=${knownHosts} ${home}/.ssh/known_hosts' -o StrictHostKeyChecking=accept-new";

          BUZZ_RELAY_URL = cfg.relayUrl;
          BUZZ_ACP_AGENT_COMMAND = a.command;
          BUZZ_ACP_AGENT_ARGS = concatStringsSep "," a.args;
          BUZZ_ACP_DISPLAY_NAME = a.displayName;
          BUZZ_ACP_SESSION_TITLE = a.displayName;
          BUZZ_ACP_RESPOND_TO = a.respondTo;
          BUZZ_ACP_RESPOND_TO_ALLOWLIST =
            if a.respondToAllowlist == [ ] then null else concatStringsSep "," a.respondToAllowlist;
          BUZZ_ACP_SESSION_POLICY = a.sessionPolicy;
          BUZZ_ACP_AGENTS = toString a.parallelism;
          BUZZ_ACP_HEARTBEAT_INTERVAL = toString a.heartbeat.interval;
          BUZZ_ACP_HEARTBEAT_PROMPT_FILE = if a.heartbeat.prompt == null then null else "${heartbeatFile}";
          BUZZ_ACP_SYSTEM_PROMPT_FILE = if a.persona == "" then null else "${personaFile}";
          BUZZ_ACP_TEAM_INSTRUCTIONS = if cfg.teamInstructions == "" then null else cfg.teamInstructions;
          BUZZ_ACP_MODEL = a.model;
          BUZZ_ACP_EFFORT_LEVEL = a.effort;
          BUZZ_ACP_MCP_COMMAND = if cfg.mcpBridge == null then null else "${mcpBridge}";
        }
        // optionalAttrs cfg.nix.enable {
          NIX_REMOTE = "daemon";
          NIX_PATH = "nixpkgs=${cfg.nix.nixpkgs}";
          NIX_CONFIG = ''
            experimental-features = nix-command flakes
            flake-registry = ${flakeRegistry}
          '';
        }
        // optionalAttrs cfg.fhsCompat {
          # lets prebuilt binaries (npm/pip wheels, vendor CLIs) run, like programs.nix-ld
          NIX_LD = pkgs.stdenv.cc.bintools.dynamicLinker;
          NIX_LD_LIBRARY_PATH = lib.makeLibraryPath cfg.fhsLibraries;
        }
        // cfg.environment
        // a.environment
      );
    in
    {
      users.users.${user} = {
        isSystemUser = true;
        inherit (a) uid;
        inherit (cfg) group;
        home = dir;
        createHome = false;
      };

      systemd.tmpfiles.rules = [
        "d ${dir} 0700 ${user} ${cfg.group} -"
        "d ${dir}/.secrets 0500 ${user} ${cfg.group} -"
      ];

      # Decrypted straight into the persistent home (copied, not symlinked into /run).
      age.secrets = lib.mapAttrs'
        (
          key: file:
            lib.nameValuePair "${user}-${key}" {
              inherit file;
              path = "${dir}/.secrets/${key}";
              symlink = false;
              owner = user;
              inherit (cfg) group;
              mode = "0400";
            }
        )
        secretFiles;

      virtualisation.oci-containers.containers.${user} = {
        image = "buzz-agent-base:nix";
        imageFile = baseImage;
        pull = "never";
        user = "${toString a.uid}:${toString cfg.gid}";
        entrypoint = "${entrypoint}";
        inherit environment;
        volumes = [
          "/nix/store:/nix/store:ro"
          "${dir}:${home}"
          "${passwd}:/etc/passwd:ro"
          "${group}:/etc/group:ro"
        ]
        ++ lib.optionals cfg.nix.enable [
          "/nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket"
        ];
        extraOptions = [
          "--hostname=${name}"
          "--read-only"
          "--tmpfs=/tmp:rw,exec,mode=1777,size=8g"
          "--security-opt=no-new-privileges"
          "--cap-drop=all"
          "--pids-limit=${toString a.resources.pids}"
        ]
        ++ lib.optional (a.resources.memory != null) "--memory=${a.resources.memory}"
        ++ lib.optional (a.resources.cpus != null) "--cpus=${a.resources.cpus}"
        ++ a.extraOptions;
      };

      # Restart when a secret is re-encrypted.
      systemd.services."podman-${user}" = {
        wants = [ "network-online.target" ];
        after = [ "network-online.target" "systemd-tmpfiles-setup.service" ]
          ++ lib.optional (config.systemd.sysusers.enable || config.services.userborn.enable) "agenix-install-secrets.service"
          ++ lib.optional cfg.nix.enable "nix-daemon.socket";
        requires = lib.optional (config.systemd.sysusers.enable || config.services.userborn.enable) "agenix-install-secrets.service";
        # Image symlinks alone do not keep their store targets alive after a GC.
        restartTriggers = attrValues secretFiles ++ [ profile pkgs.cacert ]
          ++ lib.optionals cfg.fhsCompat ([ pkgs.nix-ld ] ++ cfg.fhsLibraries);
        unitConfig.RequiresMountsFor = [ dir "/nix/store" ];
      };
    };
in
{
  options.services.buzz-agents = {
    enable = mkEnableOption "Buzz ACP agents in podman containers";

    package = mkOption {
      type = types.package;
      default = pkgs.buzz;
      defaultText = literalExpression "pkgs.buzz";
      description = "sprig multicall package providing buzz-acp, buzz, git-*-nostr.";
    };

    relayUrl = mkOption {
      type = types.str;
      example = "wss://buzz.example.com";
    };

    secretsDir = mkOption {
      type = types.path;
      description = "Holds <agent>/{nsec,authTag,githubToken,sshKey,env}.age.";
    };
    sharedEnvSecret = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "agenix env file sourced by every agent (MCP tokens, shared model keys).";
    };

    stateDir = mkOption {
      type = types.str;
      default = "/var/lib/buzz-agents";
    };
    group = mkOption {
      type = types.str;
      default = "buzz-agents";
    };
    gid = mkOption {
      type = types.ints.positive;
      default = 7100;
    };

    basePackages = mkOption {
      type = types.listOf types.package;
      default = with pkgs; [
        bashInteractive
        coreutils
        findutils
        diffutils
        gnugrep
        gnused
        gawk
        gnutar
        gzip
        xz
        zstd
        unzip
        which
        less
        file
        procps
        patch
        gnumake
        git
        git-lfs
        gh
        openssh
        curl
        wget
        jq
        yq-go
        ripgrep
        fd
        tree
        nix
        nixfmt
        nix-output-monitor
        nodejs_22
        nix-ld
        cacert
      ];
      description = "Packages every agent gets. Per-agent `packages` are appended.";
    };

    environment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Non-secret env for every agent.";
    };

    teamInstructions = mkOption {
      type = types.lines;
      default = "";
      description = "Shared instructions layered after each agent's persona.";
    };

    mcpServers = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            url = mkOption { type = types.str; };
            transport = mkOption {
              type = types.enum [
                "http"
                "sse"
              ];
              default = "http";
            };
            headers = mkOption {
              type = types.attrsOf types.str;
              default = { };
              description = "Values may use \${VAR}, substituted from the env secrets at start.";
            };
          };
        }
      );
      default = { };
      description = "Shared MCP servers, rendered to ~/.config/buzz-agents/mcp.json.";
    };
    mcpBridge = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = literalExpression ''"''${pkgs.geode}/bin/geode"'';
      description = ''
        stdio MCP aggregator (receives BUZZ_MCP_CONFIG). buzz-acp forwards exactly
        one stdio MCP server into each ACP session, so fanning out to several
        remote servers needs a single aggregator.
      '';
    };

    nix = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Allow agents to use the host nix-daemon. The read-only store is always mounted for their Nix-built tools.";
      };
      nixpkgs = mkOption {
        type = types.path;
        default = pkgs.path;
        defaultText = literalExpression "pkgs.path";
        description = "What `nixpkgs` / `<nixpkgs>` resolve to inside agents.";
      };
    };

    fhsCompat = mkOption {
      type = types.bool;
      default = true;
      description = "nix-ld shim so prebuilt dynamically linked binaries run.";
    };
    fhsLibraries = mkOption {
      type = types.listOf types.package;
      default = with pkgs; [
        stdenv.cc.cc
        zlib
        openssl
        curl
        glib
        libgcc
        icu
        libuuid
        libsecret
      ];
    };

    extraKnownHosts = mkOption {
      type = types.lines;
      default = "";
    };

    relay = {
      registerMembers = mkOption {
        type = types.bool;
        default = false;
        description = "On the relay host: add every enabled agent's pubkey as a member.";
      };
      container = mkOption {
        type = types.str;
        default = "buzz";
      };
    };

    agents = mkOption {
      type = types.attrsOf (types.submodule agentModule);
      default = { };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions =
        let
          uids = map (a: a.uid) (attrValues enabledAgents);
        in
        [
          {
            assertion = lib.length uids == lib.length (lib.unique uids);
            message = "services.buzz-agents: agent uids must be unique across the fleet";
          }
        ]
        ++ [
          {
            assertion = cfg.mcpServers == { } || cfg.mcpBridge != null;
            message = "services.buzz-agents.mcpServers requires mcpBridge to forward the configured servers.";
          }
          {
            assertion = lib.hasPrefix "/" cfg.stateDir;
            message = "services.buzz-agents.stateDir must be absolute.";
          }
        ]
        ++ lib.concatLists (mapAttrsToList
          (n: a: [
            {
              assertion = builtins.match "[a-z0-9][a-z0-9-]*" n != null;
              message = "services.buzz-agents.agents.${n}: names must contain only lowercase letters, digits, and hyphens.";
            }
            {
              assertion = a.command != "";
              message = "services.buzz-agents.agents.${n}: runtime = \"custom\" requires `command`.";
            }
            {
              assertion = a.heartbeat.interval == 0 || a.heartbeat.interval >= 10;
              message = "services.buzz-agents.agents.${n}.heartbeat.interval must be 0 or at least 10 seconds.";
            }
            {
              assertion = a.secrets.nsec != null && a.secrets.authTag != null && a.secrets.githubToken != null;
              message = "services.buzz-agents.agents.${n}: nsec, authTag, and githubToken secrets are required.";
            }
            {
              assertion = !a.github.signCommits || a.secrets.sshKey != null;
              message = "services.buzz-agents.agents.${n}: signCommits requires an sshKey secret.";
            }
          ])
          localAgents);
    }

    (mkIf (localAgents != { }) {
      users.groups.${cfg.group}.gid = cfg.gid;
      virtualisation.podman.enable = true;
      virtualisation.oci-containers.backend = "podman";
      systemd.tmpfiles.rules = [ "d ${cfg.stateDir} 0755 root root -" ];
    })

    (mkIf cfg.relay.registerMembers {
      systemd.services.buzz-agents-membership = {
        description = "Register Buzz agent pubkeys as relay members";
        wantedBy = [ "multi-user.target" ];
        requires = [ "podman-${cfg.relay.container}.service" ];
        after = [ "podman-${cfg.relay.container}.service" ];
        path = [ config.virtualisation.podman.package pkgs.coreutils ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true; # re-run on switch when the member list changes
        };
        # add-member is idempotent ("already a member ... no change")
        script = ''
          for _ in $(seq 60); do
            podman exec ${escapeShellArg cfg.relay.container} true 2>/dev/null && break
            sleep 2
          done
        ''
        + concatMapStrings
          (a: ''
            podman exec ${escapeShellArg cfg.relay.container} /usr/local/bin/buzz-admin add-member --pubkey ${a.pubkey} --role member
          '')
          (attrValues enabledAgents);
      };
    })

    # Keep the top-level shape static: a list whose length depends on
    # networking.hostName would recurse while evaluating hostName itself.
    (
      let
        parts = mapAttrsToList mkAgent localAgents;
        collect = f: mkMerge (map f parts);
      in
      {
        users.users = collect (p: p.users.users);
        age.secrets = collect (p: p.age.secrets);
        virtualisation.oci-containers.containers = collect (
          p: p.virtualisation.oci-containers.containers
        );
        systemd.tmpfiles.rules = collect (p: p.systemd.tmpfiles.rules);
        systemd.services = collect (p: p.systemd.services);
      }
    )
  ]);
}
