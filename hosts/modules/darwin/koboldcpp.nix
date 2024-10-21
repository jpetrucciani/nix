{ config, lib, pkgs, ... }:
let
  inherit (lib) literalExpression mkEnableOption filterAttrs mkIf mkOption types;
  inherit (lib) mapAttrs' nameValuePair optionalString;
  cfg = config.services.koboldcpp;
  defaultUser = "_koboldcpp";
  homeDir = "/var/lib/koboldcpp";
  koboldName = name: "kobold" + optionalString (name != "") ("-" + name);
  enabledServers = filterAttrs (name: conf: conf.enable) config.services.koboldcpp.servers;
in
{
  imports = [ ];
  options.services.koboldcpp = {
    servers = mkOption {
      type = lib.types.attrsOf (lib.types.submodule (_: {
        options = {
          enable = mkEnableOption "koboldcpp server launchd service";
          package = mkOption {
            type = types.package;
            default = pkgs.koboldcpp;
            defaultText = literalExpression "pkgs.koboldcpp";
            description = "The package to use for koboldcpp";
          };
          address = mkOption {
            type = types.str;
            default = "0.0.0.0";
            description = ''the address to bind to'';
          };
          port = mkOption {
            type = types.port;
            default = 5001;
            description = ''the port to bind to'';
          };
          model = mkOption {
            type = types.path;
            description = "the full path of the gguf file to run";
          };
          mmproj = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "the full path of a mmproj file to use, if needed";
          };
          gpulayers = mkOption {
            type = types.int;
            description = "the number of layers to offload to gpu. 0 to disable, -1 to autodetect";
            default = 0;
          };
          extraFlags = mkOption {
            type = types.str;
            description = "any extra flags to pass to koboldcpp";
            default = "";
          };
        };
      }));
    };
    user = mkOption {
      type = types.str;
      description = ''
        User under which to run the koboldcpp server.
      '';
      default = defaultUser;
    };
    group = mkOption {
      type = types.str;
      description = ''
        Group under which to run the koboldcpp server.
      '';
      default = defaultUser;
    };
  };

  config = mkIf (enabledServers != { }) {
    system.activationScripts = {
      launchd = {
        text = lib.mkBefore ''
          ${pkgs.coreutils}/bin/mkdir -p -m 0750 ${homeDir}
          ${pkgs.coreutils}/bin/chown ${cfg.user}:${cfg.group} ${homeDir}
        '';
      };
    };
    launchd.daemons = mapAttrs'
      (name: conf: nameValuePair (koboldName name) (
        let
          mmproj = if conf.mmproj != null then "--mmproj ${conf.mmproj}" else "";
          serve = pkgs.writers.writeBash "koboldcpp-${koboldName name}" ''
            ${lib.getExe' conf.package "koboldcpp"} --host '${conf.address}' --port '${toString conf.port}' --model '${conf.model}' ${mmproj} --gpulayers ${toString conf.gpulayers} ${conf.extraFlags}
          '';
        in
        {
          command = serve;
          serviceConfig = {
            GroupName = cfg.group;
            Label = "dev.cobi.kobold.${koboldName name}";
            RunAtLoad = true;
            StandardOutPath = "${homeDir}/log/${koboldName name}.out";
            StandardErrorPath = "${homeDir}/log/${koboldName name}.err";
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
        description = "koboldcpp service user";
        home = homeDir;
        shell = "/bin/bash";
        uid = lib.mkDefault 5001;
      };
      knownUsers = [ "${cfg.user}" ];
      groups."${cfg.user}" = {
        gid = lib.mkDefault 5001;
        description = "koboldcpp service user group";
      };
      knownGroups = [ "${cfg.user}" ];
    };
  };
}
