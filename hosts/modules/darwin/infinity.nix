{ config, lib, pkgs, ... }:
let
  inherit (lib) literalExpression mkEnableOption mkIf mkOption types;
  cfg = config.services.infinity;
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
      type = types.nullOr types.str;
      description = ''
        User under which to run the service.

        If this option and the `group` option is set to `null`, nix-darwin creates
        the `_infinity` user and group.
      '';
      defaultText = literalExpression "username";
      default = null;
    };

    group = mkOption {
      type = types.nullOr types.str;
      description = ''
        Group under which to run the service.

        If this option and the `user` option is set to `null`, nix-darwin creates
        the `_infinity` user and group.
      '';
      defaultText = literalExpression "groupname";
      default = null;
    };
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = cfg.models != [ ];
      message = ''no models specified!'';
    }];
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
        serviceConfig =
          let
            homeDir = "/var/lib/infinity";
          in
          {
            Label = "dev.cobi.infinity";
            RunAtLoad = true;
            StandardOutPath = "${homeDir}/infinity-out.log";
            StandardErrorPath = "${homeDir}/infinity-err.log";
            WorkingDirectory = homeDir;
          };
      };

    users =
      let
        username = if cfg.user != null then cfg.user else "";
      in
      mkIf (lib.any (cfg: cfg.enable && cfg.user == null && cfg.group == null) (lib.attrValues config.services.infinitys)) {
        users."${username}" = {
          createHome = false;
          description = "infinity service user";
          gid = config.users.groups."${username}".gid;
          home = "/var/lib/infinity";
          shell = "/bin/bash";
          uid = lib.mkDefault 799;
        };
        knownUsers = [ "${username}" ];

        groups."${username}" = {
          gid = lib.mkDefault 799;
          description = "infinity service user group";
        };
        knownGroups = [ "${username}" ];
      };
  };
}
