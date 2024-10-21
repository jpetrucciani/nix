{ config, lib, pkgs, ... }:
let
  inherit (lib) mkOption types mkIf;
  cfg = config.services.ollama;
  defaultUser = "_ollama";
  homeDir = "/var/lib/ollama";
in
{
  options = {
    services.ollama = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable the Ollama Daemon.";
      };

      package = mkOption {
        type = types.path;
        default = pkgs.ollama;
        description = "This option specifies the ollama package to use.";
      };

      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        example = "0.0.0.0";
        description = ''
          The host address which the ollama server HTTP interface listens to.
        '';
      };

      port = mkOption {
        type = types.port;
        default = 11434;
        description = ''Which port the ollama server listens to.'';
      };

      models = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "/var/lib/ollama/models";
        description = ''
          The directory that the ollama service will read models from and download new models to.
        '';
      };

      environmentVariables = mkOption {
        type = types.attrsOf types.str;
        default = { };
        example = {
          OLLAMA_LLM_LIBRARY = "cpu";
          HIP_VISIBLE_DEVICES = "0,1";
        };
        description = ''
          Set arbitrary environment variables for the ollama service.

          Be aware that these are only seen by the ollama server (launchd daemon),
          not normal invocations like `ollama run`.
          Since `ollama run` is mostly a shell around the ollama server, this is usually sufficient.
        '';
      };
      user = mkOption {
        type = types.str;
        description = ''
          User under which to run the ollama service.
        '';
        default = defaultUser;
      };
      group = mkOption {
        type = types.str;
        description = ''
          Group under which to run the ollama service.
        '';
        default = defaultUser;
      };
    };
  };

  config = mkIf cfg.enable {
    system.activationScripts = {
      launchd = mkIf cfg.enable {
        text = lib.mkBefore ''
          ${pkgs.coreutils}/bin/mkdir -p -m 0750 ${homeDir}
          ${pkgs.coreutils}/bin/chown ${cfg.user}:${cfg.group} ${homeDir}
        '';
      };
    };
    environment.systemPackages = [ cfg.package ];
    launchd.user.agents.ollama = {
      path = [ config.environment.systemPath ];

      serviceConfig = {
        KeepAlive = true;
        Label = "dev.cobi.ollama";
        RunAtLoad = true;
        StandardOutPath = "${homeDir}/log/out.log";
        StandardErrorPath = "${homeDir}/log/err.log";
        ProgramArguments = [ "${cfg.package}/bin/ollama" "serve" ];
        EnvironmentVariables = cfg.environmentVariables // {
          OLLAMA_HOST = "${cfg.host}:${toString cfg.port}";
          OLLAMA_MODELS = if cfg.models == null then "${homeDir}/models" else cfg.models;
        };
      };
    };
    users = mkIf (cfg.user == defaultUser) {
      users."${cfg.user}" = {
        inherit (config.users.groups."${cfg.user}") gid;
        createHome = false;
        description = "ollama service user";
        home = homeDir;
        shell = "/bin/bash";
        uid = lib.mkDefault 1434;
      };
      knownUsers = [ "${cfg.user}" ];
      groups."${cfg.user}" = {
        gid = lib.mkDefault 1434;
        description = "ollama service user group";
      };
      knownGroups = [ "${cfg.user}" ];
    };
  };
}
