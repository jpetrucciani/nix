{ config, lib, pkgs, ... }:
let
  inherit (lib) literalExpression mkEnableOption mkIf mkOption types;
  inherit (lib.types) listOf package port str;
  cfg = config.services.infinity;
  defaultUser = "_infinity";
  homeDir = "/private/var/lib/infinity";
in
{
  imports = [ ];

  options.services.infinity = {
    enable = mkEnableOption "infinity server launchd service";
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
        "nomic-ai/modernbert-embed-base"
        "mixedbread-ai/mxbai-rerank-base-v1"
        # "NovaSearch/stella_en_400M_v5"
        # check out the MTEB leaderboard!
        ### https://huggingface.co/spaces/mteb/leaderboard
        # "jinaai/jina-embeddings-v3"
        # "BAAI/bge-small-en-v1.5"
      ];
      description = "the list of embeddings models to load";
    };
    extraFlags = mkOption {
      type = str;
      description = "any extra flags to pass to infinity";
      default = "";
    };
    urlPrefix = mkOption {
      type = str;
      default = "/v1";
      description = "a prefix for each endpoint to have";
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
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = cfg.models != [ ];
      message = ''no models specified!'';
    }];
    system.activationScripts = {
      launchd = mkIf cfg.enable {
        text = lib.mkBefore ''
          # shellcheck disable=SC2174
          ${pkgs.coreutils}/bin/mkdir -p -m 0750 ${homeDir}
          ${pkgs.coreutils}/bin/chown ${cfg.user}:${cfg.group} ${homeDir}
        '';
      };
    };
    launchd.daemons.infinity =
      let
        models = lib.concatStringsSep " " (
          map (model: "--model-id '${lib.replaceStrings ["'"] [""] model}'") cfg.models
        );
        serve = pkgs.writers.writeBash "infinity-serve" ''
          ${lib.getExe' cfg.package "infinity_emb"} v2 ${models} ${cfg.extraFlags}
        '';
      in
      {
        command = serve;
        serviceConfig = {
          EnvironmentVariables = {
            INFINITY_HOST = cfg.address;
            INFINITY_PORT = toString cfg.port;
            INFINITY_URL_PREFIX = cfg.urlPrefix;
          };
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
        home = homeDir;
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
