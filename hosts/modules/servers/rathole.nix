{ config, pkgs, lib, ... }:
let
  inherit (lib) mkIf mkEnableOption mkOption literalExpression mdDoc;
  inherit (lib.types) enum int lines package path port str;
  cfg = config.services.rathole;

  clientService =
    { name
    , local_addr
    , type ? "tcp"
    , token ? ""
    , nodelay ? false
    }: { };
  serverService =
    { name
    , bind_addr
    , type ? "tcp"
    , token ? ""
    , nodelay ? false
    }: { };

  toml = {
    server = ''
      [server]
      bind_addr = "${cfg.bindAddress}:${cfg.bindPort}"
      default_token = "$DEFAULT_TOKEN"
      heartbeat_interval = ${cfg.heartbeatTimeout}
    '';
    client = ''
      [client]
      remote_addr = "${cfg.remoteAddress}:${cfg.remotePort}"
      default_token = "$DEFAULT_TOKEN"
      heartbeat_timeout = ${cfg.heartbeatTimeout}
    '';
  };
  configFile = pkgs.writeText "rathole.toml" ''
    ${if cfg.mode == "server" then toml.server else toml.client}
    [${cfg.mode}.transport]
    type = "${cfg.transport}"

    ${cfg.extraConfig}
  '';
in
{
  imports = [ ];

  options.services.rathole = {
    enable = mkEnableOption "rathole";
    user = mkOption {
      type = str;
      default = "rathole";
      description = mdDoc "User account under which rathole runs";
    };
    group = mkOption {
      type = str;
      default = "rathole";
      description = mdDoc "Group under which rathole runs";
    };
    dataDir = mkOption {
      type = path;
      default = "/var/lib/rathole";
      description = mdDoc ''the data directory for rathole'';
    };
    mode = mkOption {
      type = enum [ "server" "client" ];
      default = "server";
      description = mdDoc ''the type of rathole service to run'';
    };
    secretFile = mkOption {
      type = path;
      default = "/etc/default/rathole";
      description = mdDoc ''secret env variables for rathole'';
    };
    package = mkOption {
      default = pkgs.rathole;
      defaultText = literalExpression "pkgs.rathole";
      type = package;
      description = mdDoc ''rathole package to use'';
    };
    transport = mkOption {
      type = enum [ "tcp" "tls" "noise" ];
      default = "tcp";
      description = mdDoc ''the type of transport to use'';
    };


    # server specific
    bindAddress = mkOption {
      type = str;
      default = "0.0.0.0";
      description = mdDoc '''';
    };
    bindPort = mkOption {
      type = port;
      default = 2333;
      description = mdDoc '''';
    };
    heartbeatInterval = mkOption {
      type = int;
      default = 40;
      description = mdDoc '''';
    };

    # client specific
    remoteAddress = mkOption {
      type = str;
      default = "0.0.0.0";
      description = mdDoc '''';
    };
    remotePort = mkOption {
      type = port;
      default = 2333;
      description = mdDoc '''';
    };
    heartbeatTimeout = mkOption {
      type = int;
      default = 40;
      description = mdDoc '''';
    };

    # extra
    extraConfig = mkOption {
      type = lines;
      default = "";
      example = '' '';
      description = lib.mdDoc ''
        Additional lines of configuration appended to the automatically generated rathole config.
      '';
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.user} = {
      home = cfg.dataDir;
      group = cfg.group;
      createHome = true;
      isSystemUser = true;
    };
    users.groups.${cfg.group} = { };

    systemd.services.rathole = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        EnvironmentFile = cfg.secretFile;
        ExecStart = ''
          ${cfg.package}/bin/rathole --${cfg.mode} -s ( echo "cat <<EOF" ; cat ${configFile} ; echo EOF )
        '';
        Restart = "on-failure";
        StateDirectory = "rathole";
        User = cfg.user;
        WorkingDirectory = cfg.dataDir;
      };
    };
  };
}
