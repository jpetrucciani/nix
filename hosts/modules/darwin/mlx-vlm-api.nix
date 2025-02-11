{ config, lib, pkgs, ... }:
let
  inherit (lib) literalExpression mkEnableOption filterAttrs mkIf mkOption types;
  inherit (lib) mapAttrs' nameValuePair optionalString;
  cfg = config.services.mlx-vlm-api;
  defaultUser = "_mlxvlm";
  homeDir = "/private/var/lib/mlxvlm";
  mlxvlmName = name: "mlxvlm" + optionalString (name != "") ("-" + name);
  enabledServers = filterAttrs (name: conf: conf.enable) config.services.mlx-vlm-api.servers;
in
{
  imports = [ ];
  options.services.mlx-vlm-api = {
    servers = mkOption {
      type = lib.types.attrsOf (lib.types.submodule (_: {
        options = {
          enable = mkEnableOption "mlx-vlm api launchd service";
          address = mkOption {
            type = types.str;
            default = "0.0.0.0";
            description = ''the address to bind to'';
          };
          port = mkOption {
            type = types.port;
            default = 8111;
            description = ''the port to bind to'';
          };
          model = mkOption {
            type = types.path;
            default = "mlx-community/Qwen2.5-VL-7B-Instruct-4bit";
            description = "the huggingface path of the model to run";
          };
          extraFlags = mkOption {
            type = types.str;
            description = "any extra flags to pass to mlx-vlm-api";
            default = "";
          };
        };
      }));
      default = { };
    };
    user = mkOption {
      type = types.str;
      description = ''
        User under which to run the mlx-vlm-api server.
      '';
      default = defaultUser;
    };
    group = mkOption {
      type = types.str;
      description = ''
        Group under which to run the mlx-vlm-api server.
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
      (name: conf: nameValuePair (mlxvlmName name) (
        let
          serve = pkgs.writers.writeBash "mlx-vlm-api-${mlxvlmName name}" ''
            ${lib.getExe' pkgs.uv} run \
              --with 'numpy<2' \
              --with 'git+https://github.com/huggingface/transformers' \
              --with 'git+https://github.com/jpetrucciani/mlx-vlm@add_api' \
              python -m mlx_vlm.api --model ${conf.model} --host 0.0.0.0 ${conf.extraFlags} --port ${toString conf.port}
          '';
        in
        {
          command = serve;
          serviceConfig = {
            GroupName = cfg.group;
            Label = "dev.cobi.mlx-vlm-api.${mlxvlmName name}";
            RunAtLoad = true;
            StandardOutPath = "${homeDir}/log/${mlxvlmName name}.out";
            StandardErrorPath = "${homeDir}/log/${mlxvlmName name}.err";
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
        description = "mlx-vlm-api service user";
        home = homeDir;
        shell = "/bin/bash";
        uid = lib.mkDefault 801;
      };
      knownUsers = [ "${cfg.user}" ];
      groups."${cfg.user}" = {
        gid = lib.mkDefault 801;
        description = "mlx-vlm-api service user group";
      };
      knownGroups = [ "${cfg.user}" ];
    };
  };
}
