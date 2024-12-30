{ config, pkgs, lib, ... }:
let
  inherit (lib) mkIf mkEnableOption mkOption literalExpression;
  inherit (lib.types) bool listOf nullOr package path port str;
  cfg = config.services.infinity;
  defaultUser = "infinity";
in
{
  imports = [ ];

  options.services.infinity = {
    package = mkOption {
      type = package;
      default = pkgs.python312Packages.infinity-emb;
      defaultText = literalExpression "pkgs.python312Packages.infinity-emb";
      description = "The package to use for infinity";
    };
    address = mkOption {
      type = str;
      default = "0.0.0.0";
      description = ''the address to bind to'';
    };
    port = mkOption {
      type = port;
      default = 7997;
      description = ''the port to bind to'';
    };
    models = mkOption {
      type = listOf str;
      default = [
        "nomic-ai/nomic-embed-text-v1.5"
        # check out the MTEB leaderboard!
        ### https://huggingface.co/spaces/mteb/leaderboard
        # "jinaai/jina-embeddings-v3"
        # "BAAI/bge-small-en-v1.5"
        # "dunzhang/stella_en_400M_v5"  # requires xformers?
      ];
      description = "the list of embeddings models to load";
    };
    extraFlags = mkOption {
      type = str;
      description = "any extra flags to pass to infinity";
      default = "";
    };
    secretFile = mkOption {
      type = nullOr path;
      default = null;
      # default = "/etc/default/infinity";
      description = ''secret env variables for infinity'';
    };
    user = mkOption {
      type = str;
      description = ''
        User under which to run the infinity service.
      '';
      default = defaultUser;
    };
    group = mkOption {
      type = str;
      description = ''
        Group under which to run the infinity service.
      '';
      default = defaultUser;
    };
    dataDir = mkOption {
      type = path;
      default = "/var/lib/infinity";
      description = ''the data directory for infinity'';
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.user} = {
      inherit (cfg) group;
      home = cfg.dataDir;
      createHome = true;
      isSystemUser = true;
    };
    users.groups.${cfg.group} = { };

    systemd.services.infinity =
      let
        models = lib.concatStringsSep " " (
          map (model: "--model-id '${lib.replaceStrings ["'"] [""] model}'") cfg.models
        );
        serve = pkgs.writers.writeBash "infinity-serve" ''
          ${lib.getExe' cfg.package "infinity_emb"} v2 --host '${cfg.address}' --port '${toString cfg.port}' ${models} ${cfg.extraFlags}
        '';
      in
      {
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];

        environment = {
          HOME = cfg.dataDir;
          USER = cfg.user;
        };

        serviceConfig = {
          ${if cfg.secretFile != null then "EnvironmentFile" else null} = cfg.secretFile;
          ExecStart = serve;
          Restart = "on-failure";
          StateDirectory = "infinity";
          User = cfg.user;
          WorkingDirectory = cfg.dataDir;
        };
      };
  };
}
