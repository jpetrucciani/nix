{ config, lib, pkgs, ... }:
let
  inherit (lib) literalExpression mkEnableOption mkIf mkOption types;
  cfg = config.services.infinity;
  defaultUser = "_infinity";
  homeDir = "/var/lib/infinity";
in
{
  imports = [ ];

  options.services.infinity = {
    enable = mkEnableOption "infinity server launchd service";
    package = mkOption {
      type = types.package;
      default = pkgs.python312Packages.infinity-emb;
      defaultText = literalExpression "pkgs.python312Packages.infinity-emb";
      description = "The package to use for infinity";
    };
    bindAddress = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = '''';
    };
    bindPort = mkOption {
      type = types.port;
      default = 7997;
      description = '''';
    };
    models = mkOption {
      type = types.listOf types.str;
      default = [
        "BAAI/bge-small-en-v1.5"
        # check out the MTEB leaderboard!
        ### https://huggingface.co/spaces/mteb/leaderboard
        # "jinaai/jina-embeddings-v3"
        # "dunzhang/stella_en_400M_v5"  # requires xformers?
      ];
      description = "the list of embeddings models to load";
    };
    extraFlags = mkOption {
      type = types.str;
      description = "any extra flags to pass to infinity";
      default = "";
    };
    user = mkOption {
      type = types.str;
      description = ''
        User under which to run the service.
      '';
      default = defaultUser;
    };
    group = mkOption {
      type = types.str;
      description = ''
        Group under which to run the service.
      '';
      default = defaultUser;
    };
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = cfg.models != [ ];
      message = ''no models specified!'';
    }];
    system.activationScripts = {
      launchd = mkIf cfg.enable {
        text = lib.mkBefore ''
          ${pkgs.coreutils}/bin/mkdir -p -m 0750 ${homeDir}
          ${pkgs.coreutils}/bin/chown ${cfg.user}:${cfg.group} ${homeDir}
        '';
      };
    };
    environment.systemPackages = [ cfg.package ];
    launchd.daemons.infinity =
      let
        models = lib.concatStringsSep " " (
          map (model: "--model-id '${lib.replaceStrings ["'"] [""] model}'") cfg.models
        );
        serve = pkgs.writers.writeBash "infinity-serve" ''
          ${lib.getExe' cfg.package "infinity_emb"} v2 --host '${cfg.bindAddress}' --port '${toString cfg.bindPort}' ${models} ${cfg.extraFlags}
        '';
      in
      {
        command = serve;
        serviceConfig = {
          GroupName = cfg.group;
          Label = "dev.cobi.infinity";
          RunAtLoad = true;
          StandardOutPath = "${homeDir}/log/out.log";
          StandardErrorPath = "${homeDir}/log/err.log";
          UserName = cfg.user;
          WorkingDirectory = homeDir;
        };
      };

    users = mkIf (cfg.user == defaultUser) {
      users."${cfg.user}" = {
        inherit (config.users.groups."${cfg.user}") gid;
        createHome = false;
        description = "infinity service user";
        home = "/var/lib/infinity";
        shell = "/bin/bash";
        uid = lib.mkDefault 799;
      };
      knownUsers = [ "${cfg.user}" ];
      groups."${cfg.user}" = {
        gid = lib.mkDefault 799;
        description = "infinity service user group";
      };
      knownGroups = [ "${cfg.user}" ];
    };
  };
}
