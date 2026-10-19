# services.bezel-tumbler: tumbler worker identities for a bezel control plane, one rootless Podman
# container each (the hermes-agent pattern): own host user and UID, read-only root, host Nix
# daemon for repo dev envs, secrets bind-mounted read-only. Each instance connects out to bezel
# over a websocket, so the box needs no open ports.
{ config, lib, pkgs, ... }:
let
  inherit (lib) attrNames concatMap concatStringsSep filterAttrs flatten literalExpression mapAttrs mapAttrs' mapAttrsToList mkDefault mkEnableOption mkIf mkOption nameValuePair optional optionalAttrs recursiveUpdate subtractLists unique;
  inherit (lib.types) attrsOf bool enum int listOf nullOr package path str submodule;

  cfg = config.services.bezel-tumbler;
  tomlFormat = pkgs.formats.toml { };

  # Paths inside the container.
  home = "/var/lib/tumbler/home";
  # The unprivileged user everything in the container runs as. `--userns=keep-id` maps the host
  # instance user to it, so the state, secrets and Nix daemon access stay that user's.
  containerUid = 1000;
  idPair = "${toString containerUid}:${toString containerUid}";
  secrets = "/secrets";

  forgeType = submodule {
    options = {
      kind = mkOption {
        type = enum [ "github" "gitlab" "forgejo" ];
        description = "Forge API flavor.";
      };
      tokenFile = mkOption {
        type = path;
        description = "Host file with the API token used to open and update PRs/MRs.";
      };
      repos = mkOption {
        type = listOf str;
        default = [ ];
        example = [ "jpetrucciani/*" "platform/**" ];
        description = ''
          Repo paths on this host the identity may work on (`*` one segment, `**` any depth).
          Empty means every repo on the host.
        '';
      };
      apiUrl = mkOption {
        type = nullOr str;
        default = null;
        description = "API base override (GitHub Enterprise, self-hosted API paths).";
      };
    };
  };

  harnessType = submodule {
    options = {
      protocol = mkOption {
        type = enum [ "acp" "stream-json" ];
        default = "acp";
        description = "`acp` (Agent Client Protocol over stdio) or `stream-json` (`claude -p`).";
      };
      command = mkOption {
        type = listOf str;
        example = [ "claude-agent-acp" ];
        description = "Command and leading args, resolved on the container's PATH.";
      };
      packages = mkOption {
        type = listOf package;
        default = [ ];
        description = "Packages the harness needs in the image: its adapter, plus the CLI for logging in.";
      };
      models = mkOption {
        type = listOf str;
        default = [ ];
        description = "Models tasks may ask for.";
      };
      modelArgs = mkOption {
        type = nullOr (listOf str);
        default = null;
        description = "Args appended when a model is chosen, `{model}` substituted. Null keeps tumbler's `--model {model}`.";
      };
      modelEnv = mkOption {
        type = nullOr str;
        default = null;
        example = "ANTHROPIC_MODEL";
        description = "Env var that also carries the chosen model.";
      };
      env = mkOption {
        type = attrsOf str;
        default = { };
        description = "Extra env for the harness.";
      };
      envFiles = mkOption {
        type = attrsOf str;
        default = { };
        example = { CLAUDE_CODE_OAUTH_TOKEN = "/secrets/claude-token"; };
        description = ''
          Env var to container file whose trimmed contents become the value. Mount the file with
          the instance's secretFiles and refer to it as `/secrets/<name>`.
        '';
      };
    };
  };

  mountType = submodule {
    options = {
      source = mkOption {
        type = str;
        description = "Absolute host path.";
      };
      readOnly = mkOption {
        type = bool;
        default = true;
        description = "Mount read-only.";
      };
    };
  };

  instanceType = submodule ({ name, ... }: {
    options = {
      enable = mkOption {
        type = bool;
        default = true;
        description = "Whether to run this identity.";
      };

      package = mkOption {
        type = package;
        default = cfg.package;
        defaultText = literalExpression "config.services.bezel-tumbler.package";
        description = "Package providing bin/tumbler.";
      };

      profile = mkOption {
        type = str;
        default = name;
        description = "bezel profile id (`bezel-admin profile-add <profile> --host …`).";
      };

      user = mkOption {
        type = str;
        default = "tumbler-${name}";
        description = "Host user that owns the state and runs the rootless container.";
      };

      uid = mkOption {
        type = int;
        example = 32101;
        description = "Static, unique host UID, so Podman storage and state ownership stay stable.";
      };

      stateDir = mkOption {
        type = str;
        default = "/var/lib/tumbler/${name}";
        description = "Host directory for mirrors, worktrees, the event outbox and the agent's home.";
      };

      bezelUrl = mkOption {
        type = str;
        default = cfg.bezelUrl;
        defaultText = literalExpression "config.services.bezel-tumbler.bezelUrl";
        description = "Worker endpoint, e.g. `wss://bezel.example.dev/v1/worker`.";
      };

      tokenFile = mkOption {
        type = path;
        description = "Host file with this profile's worker token (printed by `profile-add`).";
      };

      maxConcurrent = mkOption {
        type = int;
        default = 1;
        description = "Runs at once.";
      };

      capabilities = mkOption {
        type = listOf str;
        default = [ ];
        example = [ "acme" ];
        description = "Tags matched against bezel's scope rules and task `needs`.";
      };

      git = {
        name = mkOption {
          type = str;
          default = name;
          description = "Commit author name.";
        };
        email = mkOption {
          type = str;
          description = "Commit author email.";
        };
        sshKeyFile = mkOption {
          type = nullOr path;
          default = null;
          description = ''
            Host file with the SSH private key used for fetches and pushes. It must be readable
            by the instance user and mode 0600.
          '';
        };
      };

      forges = mkOption {
        type = attrsOf forgeType;
        default = { };
        description = "Forges this identity can open PRs/MRs on, keyed by host (`github.com`).";
      };

      harnesses = mkOption {
        type = listOf str;
        default = attrNames cfg.harnesses;
        defaultText = literalExpression "attrNames config.services.bezel-tumbler.harnesses";
        example = [ "claude" ];
        description = "Harnesses this identity offers, by name from `services.bezel-tumbler.harnesses`.";
      };

      secretFiles = mkOption {
        type = attrsOf path;
        default = { };
        example = literalExpression ''{ claude-token = config.age.secrets.claude-token.path; }'';
        description = "Extra host files mounted read-only at `/secrets/<name>` (e.g. harness API keys).";
      };

      packages = mkOption {
        type = listOf package;
        default = [ ];
        example = literalExpression "with pkgs; [ gh glab jq ]";
        description = "Extra tools on PATH for the agent and checks, on top of the box-wide `packages`.";
      };

      settings = mkOption {
        inherit (tomlFormat) type;
        default = { };
        example = { wall_clock_secs = 3600; idle_secs = 600; };
        description = "Extra tumbler config keys, merged over the generated config.";
      };

      mounts = mkOption {
        type = attrsOf mountType;
        default = { };
        description = "Extra bind mounts, keyed by container path.";
      };

      network = mkOption {
        type = nullOr str;
        default = null;
        description = "Podman network. Null uses the rootless default (outbound internet and tailnet).";
      };

      cpus = mkOption {
        type = nullOr str;
        default = null;
        description = "CPU limit, e.g. \"4\".";
      };

      memory = mkOption {
        type = nullOr str;
        default = null;
        description = "Memory limit, e.g. \"16g\".";
      };

      pidsLimit = mkOption {
        type = int;
        default = 4096;
        description = "Process limit (builds and test runners fork a lot).";
      };

      tmpSize = mkOption {
        type = str;
        default = "4g";
        description = "Size of the /tmp tmpfs.";
      };

      stopTimeout = mkOption {
        type = int;
        default = 120;
        description = ''
          Seconds a stop or restart waits for running runs to finish before killing them. Killed
          runs are reported lost on reconnect and retried, so short is fine.
        '';
      };

      extraOptions = mkOption {
        type = listOf str;
        default = [ ];
        description = "Extra `podman run` options.";
      };

      autoStart = mkOption {
        type = bool;
        default = true;
        description = "Start at boot.";
      };
    };
  });

  enabled = filterAttrs (_: i: i.enable) cfg.instances;

  harnessToml = name: h: {
    inherit name;
    inherit (h) protocol command models;
  }
  // optionalAttrs (h.modelArgs != null) { model_args = h.modelArgs; }
  // optionalAttrs (h.modelEnv != null) { model_env = h.modelEnv; }
  // optionalAttrs (h.env != { }) { inherit (h) env; }
  // optionalAttrs (h.envFiles != { }) { env_files = h.envFiles; };

  configFile = name: i:
    tomlFormat.generate "tumbler-${name}.toml" (recursiveUpdate
      {
        inherit (i) profile capabilities;
        harness = map (n: harnessToml n cfg.harnesses.${n}) i.harnesses;
        host = config.networking.hostName;
        bezel_url = i.bezelUrl;
        token_file = "${secrets}/token";
        max_concurrent = i.maxConcurrent;
        state_dir = "/var/lib/tumbler/state";
        work_dir = "/var/lib/tumbler/work";
        # Give up draining just before podman would kill the container anyway.
        drain_timeout_secs = lib.max 1 (i.stopTimeout - 10);
        git = {
          inherit (i.git) name email;
        } // optionalAttrs (i.git.sshKeyFile != null) { ssh_key_file = "${secrets}/ssh-key"; };
        forge = mapAttrs
          (host: f: {
            inherit (f) kind repos;
            token_file = "${secrets}/forge-${host}";
          } // optionalAttrs (f.apiUrl != null) { api_url = f.apiUrl; })
          i.forges;
      }
      i.settings);

  imagePackages = i: with pkgs; [
    aq
    i.package
    bashInteractive
    cacert
    coreutils
    diffutils
    findutils
    gawk
    git
    gnugrep
    gnused
    gnutar
    gzip
    openssh
    procps
    which
    xz
    config.nix.package
  ]
  ++ concatMap (n: cfg.harnesses.${n}.packages) i.harnesses
  ++ cfg.packages
  ++ i.packages;

  # Baked into each identity's image so every git and ssh in the container, including a debug
  # shell, acts as the identity: commits carry its name and email, and SSH offers its key.
  gitConfig = i: pkgs.writeText "tumbler-gitconfig" (lib.generators.toGitINI {
    user = { inherit (i.git) name email; };
    init.defaultBranch = "main";
  });
  sshConfig = pkgs.writeText "tumbler-ssh_config" ''
    Host *
      IdentityFile ${secrets}/ssh-key
      IdentitiesOnly yes
      StrictHostKeyChecking accept-new
  '';

  mkImage = name: i:
    let
      packages = imagePackages i;
    in
    pkgs.dockerTools.streamLayeredImage {
      name = "localhost/tumbler-${name}";
      tag = "nixos";
      contents = pkgs.buildEnv {
        name = "tumbler-${name}-root";
        paths = packages;
        pathsToLink = [ "/bin" ];
        ignoreCollisions = true;
      };
      fakeRootCommands = ''
        mkdir -p etc/ssh tmp usr/bin var/lib/tumbler var/tmp
        chmod 1777 tmp var/tmp
        cp ${gitConfig i} etc/gitconfig
        ${lib.optionalString (i.git.sshKeyFile != null) "cp ${sshConfig} etc/ssh/ssh_config"}
        printf '%s\n' 'root:x:0:0:root:/var/empty:/bin/false' 'tumbler:x:${toString containerUid}:${toString containerUid}:tumbler:${home}:/bin/bash' > etc/passwd
        printf '%s\n' 'root:x:0:' 'tumbler:x:${toString containerUid}:' > etc/group
        ln -s ${pkgs.coreutils}/bin/env usr/bin/env
      '';
      config = {
        Entrypoint = [ "${i.package}/bin/tumbler" "run" "--config" "/etc/tumbler/config.toml" ];
        Env = [
          "LANG=C.UTF-8"
          "LC_ALL=C.UTF-8"
          "PATH=${lib.makeBinPath packages}"
          # Nix's git looks for its system config under its own store path.
          "GIT_CONFIG_SYSTEM=/etc/gitconfig"
          "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        ];
        User = idPair;
        WorkingDir = home;
      };
    };

  secretVolumes = i:
    [ "${toString i.tokenFile}:${secrets}/token:ro" ]
    ++ optional (i.git.sshKeyFile != null) "${toString i.git.sshKeyFile}:${secrets}/ssh-key:ro"
    ++ mapAttrsToList (host: f: "${toString f.tokenFile}:${secrets}/forge-${host}:ro") i.forges
    ++ mapAttrsToList (n: src: "${toString src}:${secrets}/${n}:ro") i.secretFiles;

  mkContainer = name: i: nameValuePair "tumbler-${name}" {
    inherit (i) autoStart;
    image = "localhost/tumbler-${name}:nixos";
    imageStream = mkImage name i;
    pull = "never";
    user = idPair;
    workdir = home;
    hostname = "tumbler-${name}";
    podman.user = i.user;
    environment = {
      HOME = home;
      RUST_LOG = "info";
      TUMBLER_LOG_JSON = "true";
      NIX_REMOTE = "daemon";
      NIX_PATH = "nixpkgs=${pkgs.path}";
      NIX_CONFIG = "experimental-features = nix-command flakes";
      NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    };
    volumes = [
      "${i.stateDir}/data:/var/lib/tumbler:rw"
      "${configFile name i}:/etc/tumbler/config.toml:ro"
      "/nix/store:/nix/store:ro"
      "/nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket:ro"
    ]
    ++ secretVolumes i
    ++ mapAttrsToList (target: m: "${m.source}:${target}:${if m.readOnly then "ro" else "rw"}") i.mounts;
    capabilities.ALL = false;
    networks = optional (i.network != null) i.network;
    extraOptions = [
      "--userns=keep-id:uid=${toString containerUid},gid=${toString containerUid}"
      "--security-opt=no-new-privileges"
      "--read-only"
      "--pids-limit=${toString i.pidsLimit}"
      "--stop-timeout=${toString i.stopTimeout}"
      "--tmpfs=/run:rw,nosuid,nodev,size=64m"
      "--tmpfs=/tmp:rw,nosuid,nodev,mode=1777,size=${i.tmpSize}"
      "--tmpfs=/var/tmp:rw,nosuid,nodev,mode=1777,size=1g"
    ]
    ++ optional (i.cpus != null) "--cpus=${i.cpus}"
    ++ optional (i.memory != null) "--memory=${i.memory}"
    ++ i.extraOptions;
  };

  instanceCases = concatStringsSep "\n" (mapAttrsToList
    (name: i: ''
      ${lib.escapeShellArg name}) user=${lib.escapeShellArg i.user}; uid=${toString i.uid}; container=tumbler-${name} ;;'')
    enabled);

  # `tumbler-podman <instance> shell` for an interactive shell (e.g. to log a harness in), or any
  # podman arguments as the instance user: `tumbler-podman laptop logs -f tumbler-laptop`.
  tumblerPodman = pkgs.writeShellApplication {
    name = "tumbler-podman";
    text = ''
      [ "$#" -ge 2 ] || { echo "usage: tumbler-podman INSTANCE {shell|PODMAN_ARGS...}" >&2; exit 2; }
      instance="$1"
      shift
      case "$instance" in
      ${instanceCases}
        *) echo "no such tumbler instance: $instance" >&2; exit 2 ;;
      esac
      if [ "$1" = "shell" ]; then
        set -- exec -it "$container" bash -li
      fi
      home=$(${pkgs.getent}/bin/getent passwd "$user" | cut -d: -f6)
      # Start in the instance's home: podman, as that user, can't read the caller's directory.
      exec ${config.security.wrapperDir}/sudo -u "$user" \
        ${pkgs.coreutils}/bin/env -C "$home" HOME="$home" XDG_RUNTIME_DIR="/run/user/$uid" \
        /run/current-system/sw/bin/podman "$@"
    '';
  };
in
{
  options.services.bezel-tumbler = {
    enable = mkEnableOption "tumbler worker identities in rootless Podman";

    package = mkOption {
      type = package;
      default = pkgs.tumbler;
      defaultText = literalExpression "pkgs.tumbler";
      description = "Package providing bin/tumbler.";
    };

    harnesses = mkOption {
      type = attrsOf harnessType;
      default = { };
      example = literalExpression ''
        {
          claude.envFiles.CLAUDE_CODE_OAUTH_TOKEN = "/secrets/claude-token";
          codex.env.CODEX_CONFIG = builtins.toJSON { model_reasoning_effort = "high"; };
          opencode = { command = [ "opencode" "acp" ]; packages = [ pkgs.opencode ]; };
        }
      '';
      description = ''
        Harnesses instances can offer, by name. `claude` and `codex` are predefined (each field at
        default priority, so they can be adjusted or extended); add others here.
      '';
    };

    packages = mkOption {
      type = listOf package;
      default = [ ];
      example = literalExpression "with pkgs; [ gh jq ripgrep ]";
      description = "Tools on PATH in every instance on this box.";
    };

    bezelUrl = mkOption {
      type = str;
      example = "wss://bezel.example.dev/v1/worker";
      description = "Default worker endpoint for every instance.";
    };

    instances = mkOption {
      type = attrsOf instanceType;
      default = { };
      description = "Worker identities, each in its own rootless container.";
    };
  };

  config = mkIf cfg.enable {
    # Field by field at default priority, so a host can change one field (or add an env var)
    # and keep the rest.
    services.bezel-tumbler.harnesses = {
      claude = {
        command = mkDefault [ "claude-agent-acp" ];
        modelEnv = mkDefault "ANTHROPIC_MODEL";
        packages = mkDefault (with pkgs; [ claude-agent-acp claude-code ]);
      };
      codex = {
        command = mkDefault [ "codex-acp" ];
        packages = mkDefault (with pkgs; [ codex-acp codex-latest ]);
        # The container is the sandbox and tumbler approves every permission request, so
        # codex's own sandbox and approval reviews only slow runs down. Everything else (model,
        # reasoning effort, ...) lives in ~/.codex/config.toml in the persistent home, where
        # you and the agent can change it; `env.CODEX_CONFIG` (JSON) pins settings from Nix.
        env.INITIAL_AGENT_MODE = mkDefault "agent-full-access";
      };
    };

    assertions = [
      {
        assertion = config.virtualisation.oci-containers.backend == "podman";
        message = "services.bezel-tumbler needs virtualisation.oci-containers.backend = \"podman\".";
      }
      {
        assertion = let uids = mapAttrsToList (_: i: i.uid) enabled; in builtins.length uids == builtins.length (unique uids);
        message = "Each services.bezel-tumbler instance needs a distinct uid.";
      }
      {
        assertion = let users = mapAttrsToList (_: i: i.user) enabled; in builtins.length users == builtins.length (unique users);
        message = "Each services.bezel-tumbler instance needs a distinct user.";
      }
    ] ++ flatten (mapAttrsToList
      (name: i: [
        {
          assertion = builtins.match "[a-z0-9][a-z0-9-]*" name != null;
          message = "services.bezel-tumbler.instances.${name}: use lowercase letters, digits and hyphens.";
        }
        {
          assertion = subtractLists (attrNames cfg.harnesses) i.harnesses == [ ];
          message = "services.bezel-tumbler.instances.${name}.harnesses names unknown harnesses: ${concatStringsSep ", " (subtractLists (attrNames cfg.harnesses) i.harnesses)}.";
        }
        {
          assertion = lib.hasPrefix "/" i.stateDir;
          message = "services.bezel-tumbler.instances.${name}.stateDir must be absolute.";
        }
      ])
      enabled);

    users.groups = mapAttrs' (_: i: nameValuePair i.user { }) enabled;
    users.users = mapAttrs'
      (_: i: nameValuePair i.user {
        inherit (i) uid;
        group = i.user;
        isSystemUser = true;
        home = "${i.stateDir}/podman";
        createHome = true;
        homeMode = "0700";
        linger = true;
        autoSubUidGidRange = true;
      })
      enabled;

    systemd.tmpfiles.rules = flatten (mapAttrsToList
      (_: i: map (d: "d ${i.stateDir}${d} 0700 ${i.user} ${i.user} -") [
        ""
        "/podman"
        "/data"
        "/data/home"
        "/data/home/.ssh"
        "/data/state"
        "/data/work"
      ])
      enabled);

    environment.systemPackages = [ tumblerPodman ];

    systemd.services = mapAttrs'
      (name: i: nameValuePair "podman-tumbler-${name}" {
        wants = [ "nix-daemon.socket" "network-online.target" ];
        after = [ "nix-daemon.socket" "network-online.target" ];
        unitConfig.RequiresMountsFor = [ "/nix/store" ];
        # `podman stop` waits --stop-timeout; the unit must outlast it.
        serviceConfig.TimeoutStopSec = lib.mkForce (i.stopTimeout + 30);
      })
      enabled;

    virtualisation.oci-containers = {
      backend = "podman";
      containers = mapAttrs' mkContainer enabled;
    };
  };
}
