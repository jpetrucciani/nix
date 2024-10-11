{ config, lib, pkgs, ... }:
let
  inherit (lib) literalExpression mkEnableOption mkIf mkOption types;
  cfg = config.services.llama-server;
in
{
  imports = [ ];

  options.services.llama-server = {
    enable = mkEnableOption "llama-cpp server launchd service";
    package = mkOption {
      type = types.package;
      default = pkgs.llama-cpp;
      defaultText = literalExpression "pkgs.llama-cpp";
      description = "The package to use for llama-server";
    };
    bindAddress = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = '''';
    };
    bindPort = mkOption {
      type = types.port;
      default = 8000;
      description = '''';
    };
    model = mkOption {
      type = types.str;
      description = "the full path of the gguf file to run";
    };
    ngl = mkOption {
      type = types.int;
      description = "the number of layers to offload to gpu";
      default = 0;
    };
    extraFlags = mkOption {
      type = types.str;
      description = "any extra flags to pass to llama-server";
      default = "";
    };
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = cfg.model != "";
      message = ''no model specified!'';
    }];
    environment.systemPackages = [ cfg.package ];
    launchd.daemons.llama-server =
      let
        serve = pkgs.writers.writeBash "llama-serve" ''
          ${lib.getExe' cfg.package "llama-server"} --host '${cfg.bindAddress}' --port '${toString cfg.bindPort}' --model '${cfg.model}' -ngl ${toString cfg.ngl} ${cfg.extraFlags}
        '';
      in
      {
        command = serve;
        serviceConfig = {
          Label = "dev.cobi.llama-server";
          RunAtLoad = true;
        };
      };
  };
}
