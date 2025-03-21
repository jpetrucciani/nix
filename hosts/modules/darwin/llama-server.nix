{ config, lib, pkgs, ... }:
let
  inherit (lib) literalExpression mkEnableOption filterAttrs mkIf mkOption types;
  inherit (lib) mapAttrs' nameValuePair optionalString;
  cfg = config.services.llama-server;
  defaultUser = "_llama";
  homeDir = "/private/var/lib/llama";
  llamaName = name: "llama" + optionalString (name != "") ("-" + name);
  enabledServers = filterAttrs (name: conf: conf.enable) config.services.llama-server.servers;
in
{
  imports = [ ];
  options.services.llama-server = {
    servers = mkOption {
      type = lib.types.attrsOf (lib.types.submodule (_: {
        options = {
          enable = mkEnableOption "llama-cpp server launchd service";
          package = mkOption {
            type = types.package;
            default = pkgs.llama-cpp;
            defaultText = literalExpression "pkgs.llama-cpp";
            description = "The package to use for llama-server. defaults to jacobi's latest llama-cpp overlay";
          };
          address = mkOption {
            type = types.str;
            default = "0.0.0.0";
            description = ''the address to bind to'';
          };
          port = mkOption {
            type = types.port;
            default = 8000;
            description = ''the port to bind to'';
          };
          model = mkOption {
            type = types.path;
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
      }));
      default = { };
    };
    user = mkOption {
      type = types.str;
      description = ''
        User under which to run the llama server.
      '';
      default = defaultUser;
    };
    group = mkOption {
      type = types.str;
      description = ''
        Group under which to run the llama server.
      '';
      default = defaultUser;
    };
  };

  config = mkIf (enabledServers != { }) {
    system.activationScripts = {
      launchd = {
        text = lib.mkBefore ''
          # shellcheck disable=SC2174
          ${pkgs.coreutils}/bin/mkdir -p -m 0750 ${homeDir}
          ${pkgs.coreutils}/bin/chown ${cfg.user}:${cfg.group} ${homeDir}
        '';
      };
    };
    launchd.daemons = mapAttrs'
      (name: conf: nameValuePair (llamaName name) (
        let
          serve = pkgs.writers.writeBash "llama-serve-${llamaName name}" ''
            ${lib.getExe' conf.package "llama-server"} --host '${conf.address}' --port '${toString conf.port}' --model '${conf.model}' -ngl ${toString conf.ngl} ${conf.extraFlags}
          '';
        in
        {
          command = serve;
          serviceConfig = {
            GroupName = cfg.group;
            Label = "dev.cobi.llama-server.${llamaName name}";
            RunAtLoad = true;
            StandardOutPath = "${homeDir}/log/${llamaName name}.out";
            StandardErrorPath = "${homeDir}/log/${llamaName name}.err";
            UserName = cfg.user;
            WorkingDirectory = homeDir;
          };
        }
      ))
      enabledServers;
    users = mkIf (cfg.user == defaultUser) {
      users."${cfg.user}" = {
        inherit (config.users.groups."${cfg.user}") gid;
        createHome = false;
        description = "llama service user";
        home = homeDir;
        shell = "/bin/bash";
        uid = lib.mkDefault 800;
      };
      knownUsers = [ "${cfg.user}" ];
      groups."${cfg.user}" = {
        gid = lib.mkDefault 800;
        description = "llama service user group";
      };
      knownGroups = [ "${cfg.user}" ];
    };
  };
}
