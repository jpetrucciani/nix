{ config, lib, pkgs, ... }:

let
  cfg = config.services.nvme-exporter;

  exporterBin =
    if cfg.binary != null then toString cfg.binary
    else if cfg.package != null then "${cfg.package}/bin/nvme-exporter"
    else throw "services.nvme-exporter: set either `package` or `binary`";

  listen = "${cfg.listenAddress}:${toString cfg.port}";

  extraArgsStr =
    lib.optionalString (cfg.extraArgs != [ ])
      (" " + lib.escapeShellArgs cfg.extraArgs);
in
{
  options.services.nvme-exporter = {
    enable = lib.mkEnableOption "NVMe Prometheus Exporter (nvme-exporter)";

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = pkgs.nvme-exporter;
      example = lib.literalExpression "pkgs.nvme-exporter";
      description = ''
        Package that provides `bin/nvme-exporter`.

        Set this OR set `binary` to an absolute path.
      '';
    };

    binary = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = lib.literalExpression "/usr/local/bin/nvme-exporter";
      description = ''
        Absolute path to the `nvme-exporter` executable.
        If set, it takes precedence over `package`.
      '';
    };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "IP/host address to bind to (matches `--listen-address`).";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 9998;
      description = "TCP port to listen on.";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra CLI args appended to the nvme-exporter command.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the listen port in the NixOS firewall.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "root";
      description = "User to run the service as.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "root";
      description = "Group to run the service as.";
    };

    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "disk" ];
      description = ''
        Extra groups for the service user (useful if you need read access to /dev/nvme*).

        Note: adding `disk` is broad access; a tighter option is a udev rule that assigns
        NVMe nodes to `group` with 0660 permissions.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups = lib.optionalAttrs (cfg.group != "root") {
      ${cfg.group} = { };
    };

    users.users = lib.optionalAttrs (cfg.user != "root") {
      ${cfg.user} = {
        isSystemUser = true;
        inherit (cfg) group;
        inherit (cfg) extraGroups;
        description = "NVMe Prometheus exporter service user";
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];

    systemd.services.nvme-exporter = {
      description = "NVMe Prometheus Exporter";

      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${exporterBin} --listen-address ${listen}${extraArgsStr}";

        Restart = "on-failure";
        RestartSec = "5s";

        User = cfg.user;
        Group = cfg.group;

        NoNewPrivileges = true;
        PrivateTmp = true;
        PrivateDevices = false; # matches `PrivateDevices=no`
        ProtectSystem = "strict";
        ProtectHome = true;

        DeviceAllow = [ "/dev/nvme* r" ];

        AmbientCapabilities = "CAP_SYS_RAWIO";
        CapabilityBoundingSet = "CAP_SYS_RAWIO";
      };
    };
  };
}
