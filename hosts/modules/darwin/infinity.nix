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
        # "dunzhang/stella_en_400M_v5"
      ];
      description = "the list of embeddings models to load";
    };
    extraFlags = mkOption {
      type = types.str;
      description = "any extra flags to pass to infinity";
      default = "";
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
          lib.imap0 (i: model: "--model-id $model_${toString i}") cfg.models
        );
        serve = pkgs.writers.writeBash "infinity-serve" ''
          ${lib.getExe' cfg.package "infinity_emb"} --host '${cfg.bindAddress}' --port '${toString cfg.bindPort}' ${models} ${cfg.extraFlags}
        '';
      in
      {
        command = serve;
        serviceConfig = {
          Label = "dev.cobi.infinity";
          RunAtLoad = true;
        };
      };
  };
}
