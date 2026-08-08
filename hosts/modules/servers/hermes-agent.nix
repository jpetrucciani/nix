{ config
, lib
, pkgs
, ...
}:
let
  inherit (lib)
    concatStringsSep
    filterAttrs
    flatten
    literalExpression
    mapAttrs'
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    nameValuePair
    optional
    optionalAttrs
    unique
    ;
  inherit (lib.types)
    attrsOf
    bool
    int
    listOf
    nullOr
    package
    path
    str
    submodule
    ;

  cfg = config.services.hermes-agent;
  yamlFormat = pkgs.formats.yaml { };

  mountType = submodule {
    options = {
      source = mkOption {
        type = str;
        description = "Absolute host path to mount into the Hermes container.";
        example = "/srv/projects/example";
      };

      readOnly = mkOption {
        type = bool;
        default = true;
        description = "Whether the mount is read-only inside the container.";
      };
    };
  };

  instanceType = submodule (
    { name, ... }:
    {
      options = {
        enable = mkOption {
          type = bool;
          default = true;
          description = "Whether to run this Hermes agent instance.";
        };

        package = mkOption {
          type = package;
          default = cfg.package;
          defaultText = literalExpression "config.services.hermes-agent.package";
          description = "Hermes Agent package to include in the container image.";
        };

        user = mkOption {
          type = str;
          default = "hermes-${name}";
          description = ''
            Host system user that owns this instance's state and runs its
            rootless Podman container.
          '';
        };

        group = mkOption {
          type = str;
          default = "hermes-${name}";
          description = "Host system group for this Hermes instance.";
        };

        uid = mkOption {
          type = int;
          description = ''
            Static host UID for the rootless Podman user. This must be unique
            and remain stable so Podman runtime paths and state ownership do not
            change across rebuilds.
          '';
          example = 32001;
        };

        supplementaryGroups = mkOption {
          type = listOf str;
          default = [ ];
          description = ''
            Additional host groups for access to bind-mounted paths. Host DAC
            permissions still apply even when a mount is writable.
          '';
        };

        stateDir = mkOption {
          type = str;
          default = "/var/lib/hermes-agent/${name}";
          description = ''
            Host directory containing the instance's Hermes state and isolated
            CLI home.
          '';
        };

        podmanHome = mkOption {
          type = str;
          default = "/var/lib/hermes-agent/${name}/podman";
          description = ''
            Home directory for the rootless Podman user. Podman's image and
            container storage lives below this directory.
          '';
        };

        command = mkOption {
          type = listOf str;
          default = [
            "gateway"
            "run"
          ];
          description = "Arguments passed to the hermes entrypoint.";
        };

        packages = mkOption {
          type = listOf package;
          default = [ ];
          description = ''
            Additional CLI and MCP packages available on PATH inside this
            instance only.
          '';
          example = literalExpression ''
            with pkgs; [
              gh
              jq
            ]
          '';
        };

        settings = mkOption {
          inherit (yamlFormat) type;
          default = { };
          description = ''
            Non-secret Hermes settings rendered as the immutable managed scope
            at /etc/hermes/config.yaml. These values override mutable settings
            in the instance's Hermes home.
          '';
          example = literalExpression ''
            {
              model.default = "anthropic/claude-sonnet-4";
              terminal = {
                backend = "local";
                cwd = "/workspace";
              };
              tool_loop_guardrails.hard_stop_enabled = true;
            }
          '';
        };

        environment = mkOption {
          type = attrsOf str;
          default = { };
          description = ''
            Non-secret environment variables for the container. Use
            environmentFiles for API keys and tokens because these values are
            written to the Nix store.
          '';
        };

        environmentFiles = mkOption {
          type = listOf path;
          default = [ ];
          description = ''
            Runtime environment files containing API keys, MCP credentials, and
            other secrets. The rootless Podman user must be able to read them.
          '';
          example = literalExpression ''
            [ config.age.secrets.hermes-coder-env.path ]
          '';
        };

        mounts = mkOption {
          type = attrsOf mountType;
          default = { };
          description = ''
            Explicit host bind mounts keyed by their absolute path inside the
            container. Mounts are read-only unless readOnly is set to false.
          '';
          example = literalExpression ''
            {
              "/workspace/cfg" = {
                source = "/home/jacobi/cfg";
                readOnly = false;
              };
              "/var/lib/hermes/home/.ssh/id_ed25519" = {
                source = config.age.secrets.hermes-coder-ssh.path;
              };
            }
          '';
        };

        writeSafeRoots = mkOption {
          type = nullOr (listOf str);
          default = null;
          description = ''
            Paths supplied to HERMES_WRITE_SAFE_ROOT. The default permits the
            Hermes state directory and every writable mount. Set this to an
            empty list to leave HERMES_WRITE_SAFE_ROOT unset.
          '';
        };

        ports = mkOption {
          type = listOf str;
          default = [ ];
          description = ''
            Podman port mappings. Bind to 127.0.0.1 explicitly when a port
            should not be reachable from the network.
          '';
          example = [ "127.0.0.1:8642:8642" ];
        };

        network = mkOption {
          type = nullOr str;
          default = null;
          description = ''
            Podman network for the instance. Null uses Podman's rootless
            default; use "none" for an air-gapped agent.
          '';
        };

        cpus = mkOption {
          type = nullOr str;
          default = null;
          description = "CPU limit passed to Podman, for example \"2\" or \"1.5\".";
        };

        memory = mkOption {
          type = nullOr str;
          default = null;
          description = "Memory limit passed to Podman, for example \"4g\".";
        };

        pidsLimit = mkOption {
          type = int;
          default = 512;
          description = "Maximum number of processes in the container.";
        };

        readOnlyRootFilesystem = mkOption {
          type = bool;
          default = true;
          description = "Whether to make the container root filesystem read-only.";
        };

        extraOptions = mkOption {
          type = listOf str;
          default = [ ];
          description = ''
            Additional podman run options. Options such as --privileged,
            additional capabilities, or host namespace sharing weaken the
            sandbox.
          '';
        };

        autoStart = mkOption {
          type = bool;
          default = true;
          description = "Whether to start the instance automatically at boot.";
        };
      };
    }
  );

  enabledInstances = filterAttrs (_: instance: instance.enable) cfg.instances;

  instancePaths = instance: {
    hermes = "${instance.stateDir}/hermes";
    home = "${instance.stateDir}/hermes/home";
  };

  basePackages = instance: with pkgs; [
    instance.package
    bashInteractive
    cacert
    coreutils
    findutils
    gawk
    gnugrep
    gnused
  ] ++ instance.packages;

  mkImage = name: instance:
    let
      packages = basePackages instance;
      root = pkgs.buildEnv {
        name = "hermes-agent-${name}-root";
        paths = packages;
        pathsToLink = [ "/bin" ];
        ignoreCollisions = true;
      };
    in
    pkgs.dockerTools.streamLayeredImage {
      name = "localhost/hermes-agent-${name}";
      tag = "nixos";
      contents = root;
      fakeRootCommands = ''
        mkdir -p etc tmp usr/bin var/lib/hermes/home var/tmp
        chmod 1777 tmp var/tmp
        printf '%s\n' 'root:x:0:0:Hermes Agent:/var/lib/hermes/home:/bin/bash' > etc/passwd
        printf '%s\n' 'root:x:0:' > etc/group
        ln -s ${pkgs.coreutils}/bin/env usr/bin/env
      '';
      config = {
        Entrypoint = [ "${instance.package}/bin/hermes" ];
        Env = [
          "LANG=C.UTF-8"
          "LC_ALL=C.UTF-8"
          "PATH=${lib.makeBinPath packages}"
          "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        ];
        User = "0:0";
        WorkingDir = "/var/lib/hermes/home";
      };
    };

  mkManagedConfig = name: instance:
    yamlFormat.generate "hermes-agent-${name}-managed.yaml" instance.settings;

  mountToVolume = target: mount:
    "${mount.source}:${target}:${if mount.readOnly then "ro" else "rw"}";

  automaticWriteSafeRoots = instance:
    [ "/var/lib/hermes" ]
    ++ mapAttrsToList (target: _: target) (filterAttrs (_: mount: !mount.readOnly) instance.mounts);

  resolvedWriteSafeRoots = instance:
    if instance.writeSafeRoots == null then automaticWriteSafeRoots instance else instance.writeSafeRoots;

  mkContainer = name: instance:
    let
      containerName = "hermes-agent-${name}";
      image = mkImage name instance;
      paths = instancePaths instance;
      writeSafeRoots = resolvedWriteSafeRoots instance;
    in
    nameValuePair containerName {
      inherit (instance) autoStart environmentFiles ports;
      image = "localhost/hermes-agent-${name}:nixos";
      imageStream = image;
      pull = "never";
      cmd = instance.command;
      user = "0:0";
      workdir = "/var/lib/hermes/home";
      hostname = containerName;
      podman.user = instance.user;
      environment = instance.environment // {
        HERMES_HOME = "/var/lib/hermes";
        HERMES_MANAGED_DIR = "/etc/hermes";
        HOME = "/var/lib/hermes/home";
        PYTHONDONTWRITEBYTECODE = "1";
      } // optionalAttrs (writeSafeRoots != [ ]) {
        HERMES_WRITE_SAFE_ROOT = concatStringsSep ":" writeSafeRoots;
      };
      volumes = [
        "${paths.hermes}:/var/lib/hermes:rw"
      ]
      ++ optional (instance.settings != { }) "${mkManagedConfig name instance}:/etc/hermes/config.yaml:ro"
      ++ mapAttrsToList mountToVolume instance.mounts;
      capabilities.ALL = false;
      networks = optional (instance.network != null) instance.network;
      extraOptions = [
        "--security-opt=no-new-privileges"
        "--pids-limit=${toString instance.pidsLimit}"
        "--tmpfs=/run:rw,nosuid,nodev,size=64m"
        "--tmpfs=/tmp:rw,nosuid,nodev,size=512m"
        "--tmpfs=/var/tmp:rw,nosuid,nodev,size=256m"
      ]
      ++ optional instance.readOnlyRootFilesystem "--read-only"
      ++ optional (instance.cpus != null) "--cpus=${instance.cpus}"
      ++ optional (instance.memory != null) "--memory=${instance.memory}"
      ++ instance.extraOptions;
    };

  reservedMountTargets = [
    "/etc/hermes/config.yaml"
    "/var/lib/hermes"
    "/var/lib/hermes/home"
  ];

  instanceAssertions = name: instance:
    let
      mountTargets = builtins.attrNames instance.mounts;
    in
    [
      {
        assertion = builtins.match "[a-z0-9][a-z0-9-]*" name != null;
        message = ''
          services.hermes-agent.instances.${name}: instance names may contain
          only lowercase letters, digits, and hyphens.
        '';
      }
      {
        assertion = lib.hasPrefix "/" instance.stateDir;
        message = "services.hermes-agent.instances.${name}.stateDir must be absolute.";
      }
      {
        assertion = lib.hasPrefix "/" instance.podmanHome;
        message = "services.hermes-agent.instances.${name}.podmanHome must be absolute.";
      }
      {
        assertion = instance.pidsLimit > 0;
        message = "services.hermes-agent.instances.${name}.pidsLimit must be positive.";
      }
      {
        assertion = instance.uid > 0;
        message = "services.hermes-agent.instances.${name}.uid must be positive.";
      }
      {
        assertion = builtins.all (target: lib.hasPrefix "/" target) mountTargets;
        message = "services.hermes-agent.instances.${name}.mounts targets must be absolute.";
      }
      {
        assertion = builtins.all (mount: lib.hasPrefix "/" mount.source) (builtins.attrValues instance.mounts);
        message = "services.hermes-agent.instances.${name}.mounts sources must be absolute.";
      }
      {
        assertion = builtins.all (target: !(builtins.elem target reservedMountTargets)) mountTargets;
        message = "services.hermes-agent.instances.${name}.mounts overrides a module-managed path.";
      }
    ];
in
{
  options.services.hermes-agent = {
    enable = mkEnableOption "sandboxed Hermes Agent instances";

    package = mkOption {
      type = package;
      default = pkgs.hermes-agent;
      defaultText = literalExpression "pkgs.hermes-agent";
      description = "Default Hermes Agent package for all instances.";
    };

    instances = mkOption {
      type = attrsOf instanceType;
      default = { };
      description = "Hermes Agent instances, each isolated in its own rootless Podman container.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.virtualisation.oci-containers.backend == "podman";
        message = "services.hermes-agent requires virtualisation.oci-containers.backend = \"podman\".";
      }
      {
        assertion =
          let
            users = mapAttrsToList (_: instance: instance.user) enabledInstances;
          in
          builtins.length users == builtins.length (unique users);
        message = "Each enabled services.hermes-agent instance must use a distinct host user.";
      }
      {
        assertion =
          let
            uids = mapAttrsToList (_: instance: instance.uid) enabledInstances;
          in
          builtins.length uids == builtins.length (unique uids);
        message = "Each enabled services.hermes-agent instance must use a distinct host UID.";
      }
    ] ++ flatten (mapAttrsToList instanceAssertions enabledInstances);

    users.groups = mapAttrs' (_: instance: nameValuePair instance.group { }) enabledInstances;

    users.users = mapAttrs'
      (
        _: instance:
          nameValuePair instance.user {
            inherit (instance) group uid;
            extraGroups = instance.supplementaryGroups;
            isSystemUser = true;
            home = instance.podmanHome;
            createHome = true;
            homeMode = "0700";
            linger = true;
            autoSubUidGidRange = true;
          }
      )
      enabledInstances;

    systemd.tmpfiles.rules = flatten (
      mapAttrsToList
        (
          _: instance:
            let
              paths = instancePaths instance;
            in
            [
              "d ${instance.stateDir} 0700 ${instance.user} ${instance.group} -"
              "d ${paths.hermes} 0700 ${instance.user} ${instance.group} -"
              "d ${paths.home} 0700 ${instance.user} ${instance.group} -"
              "d ${paths.home}/.ssh 0700 ${instance.user} ${instance.group} -"
              "d ${instance.podmanHome} 0700 ${instance.user} ${instance.group} -"
            ]
        )
        enabledInstances
    );

    virtualisation.oci-containers = {
      backend = "podman";
      containers = mapAttrs' mkContainer enabledInstances;
    };
  };
}
