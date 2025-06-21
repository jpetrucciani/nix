{ config, lib, pkgs, ... }:
let
  inherit (lib) mkEnableOption filterAttrs mkIf mkOption types;
  inherit (lib) mapAttrs' nameValuePair optionalString concatMapStringsSep;
  inherit (lib) concatStringsSep mapAttrsToList;

  pkg = pkgs._3proxy;
  cfg = config.services._3proxy;
  defaultUser = "_3proxy";
  homeDir = "/private/var/lib/3proxy";

  optionalList = list: if list == [ ] then "*" else concatMapStringsSep "," toString list;

  enabledServers = filterAttrs (name: conf: conf.enable) config.services._3proxy.servers;

  proxyName = name: "3proxy" + optionalString (name != "") ("-" + name);

  generateConfig = serverConf: pkgs.writeText "3proxy-${serverConf.name}.conf" ''
    # log to stdout
    log
    
    ${concatMapStringsSep "\n" (x: "nserver " + x) cfg.resolution.nserver}
    
    nscache ${toString cfg.resolution.nscache}
    nscache6 ${toString cfg.resolution.nscache6}
    
    ${concatMapStringsSep "\n" (x: "nsrecord " + x) (
      mapAttrsToList (name: value: "${name} ${value}") cfg.resolution.nsrecord
    )}
    
    ${optionalString (cfg.usersFile != null) ''users $"${cfg.usersFile}"''}
    
    auth ${concatStringsSep " " serverConf.auth}
    
    ${optionalString cfg.denyPrivate "deny * * ${optionalList cfg.privateRanges}"}
    
    ${concatMapStringsSep "\n" (
      acl:
      "${acl.rule} ${
        concatMapStringsSep " " optionalList [
          acl.users
          acl.sources
          acl.targets
          acl.targetPorts
        ]
      }"
    ) serverConf.acl}
    
    maxconn ${toString serverConf.maxConnections}
    
    ${optionalString (serverConf.extraConfig != null) serverConf.extraConfig}
    
    ${serverConf.type} -i${toString serverConf.bindAddress} ${
      optionalString (serverConf.bindPort != null) "-p${toString serverConf.bindPort}"
    } ${optionalString (serverConf.extraArguments != null) serverConf.extraArguments}
    
    flush
    ${optionalString (cfg.extraConfig != null) cfg.extraConfig}
  '';
in
{
  imports = [ ];

  options.services._3proxy = {
    servers = mkOption {
      type = lib.types.attrsOf (lib.types.submodule (_: {
        options = {
          enable = mkEnableOption "3proxy launchd service";

          type = mkOption {
            type = lib.types.enum [
              "proxy"
              "socks"
              "pop3p"
              "ftppr"
              "admin"
              "dnspr"
              "tcppm"
              "udppm"
            ];
            example = "proxy";
            description = ''
              Service type. The following values are valid:

              - `"proxy"`: HTTP/HTTPS proxy (default port 3128).
              - `"socks"`: SOCKS 4/4.5/5 proxy (default port 1080).
              - `"pop3p"`: POP3 proxy (default port 110).
              - `"ftppr"`: FTP proxy (default port 21).
              - `"admin"`: Web interface (default port 80).
              - `"dnspr"`: Caching DNS proxy (default port 53).
              - `"tcppm"`: TCP portmapper.
              - `"udppm"`: UDP portmapper.
            '';
          };

          bindAddress = mkOption {
            type = lib.types.str;
            default = "[::]";
            example = "127.0.0.1";
            description = ''
              Address used for service.
            '';
          };

          bindPort = mkOption {
            type = lib.types.nullOr lib.types.int;
            default = null;
            example = 3128;
            description = ''
              Override default port used for service.
            '';
          };

          maxConnections = mkOption {
            type = lib.types.int;
            default = 100;
            example = 1000;
            description = ''
              Maximum number of simulationeous connections to this service.
            '';
          };

          auth = mkOption {
            type = lib.types.listOf (
              lib.types.enum [
                "none"
                "iponly"
                "strong"
              ]
            );
            default = [ "none" ];
            example = [
              "iponly"
              "strong"
            ];
            description = ''
              Authentication type. The following values are valid:

              - `"none"`: disables both authentication and authorization. You can not use ACLs.
              - `"iponly"`: specifies no authentication. ACLs authorization is used.
              - `"strong"`: authentication by username/password. If user is not registered their access is denied regardless of ACLs.

              Double authentication is possible, e.g.

              ```
                {
                  auth = [ "iponly" "strong" ];
                  acl = [
                    {
                      rule = "allow";
                      targets = [ "192.168.0.0/16" ];
                    }
                    {
                      rule = "allow"
                      users = [ "user1" "user2" ];
                    }
                  ];
                }
              ```
              In this example strong username authentication is not required to access 192.168.0.0/16.
            '';
          };

          acl = mkOption {
            type = lib.types.listOf (
              lib.types.submodule {
                options = {
                  rule = mkOption {
                    type = lib.types.enum [
                      "allow"
                      "deny"
                    ];
                    example = "allow";
                    description = ''
                      ACL rule. The following values are valid:

                      - `"allow"`: connections allowed.
                      - `"deny"`: connections not allowed.
                    '';
                  };
                  users = mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [ ];
                    example = [
                      "user1"
                      "user2"
                      "user3"
                    ];
                    description = ''
                      List of users, use empty list for any.
                    '';
                  };
                  sources = mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [ ];
                    example = [
                      "127.0.0.1"
                      "192.168.1.0/24"
                    ];
                    description = ''
                      List of source IP range, use empty list for any.
                    '';
                  };
                  targets = mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [ ];
                    example = [
                      "127.0.0.1"
                      "192.168.1.0/24"
                    ];
                    description = ''
                      List of target IP ranges, use empty list for any.
                      May also contain host names instead of addresses.
                      It's possible to use wildmask in the beginning and in the the end of hostname, e.g. `*badsite.com` or `*badcontent*`.
                      Hostname is only checked if hostname presents in request.
                    '';
                  };
                  targetPorts = mkOption {
                    type = lib.types.listOf lib.types.int;
                    default = [ ];
                    example = [
                      80
                      443
                    ];
                    description = ''
                      List of target ports, use empty list for any.
                    '';
                  };
                };
              }
            );
            default = [ ];
            example = lib.literalExpression ''
              [
                {
                  rule = "allow";
                  users = [ "user1" ];
                }
                {
                  rule = "allow";
                  sources = [ "192.168.1.0/24" ];
                }
                {
                  rule = "deny";
                }
              ]
            '';
            description = ''
              Use this option to limit user access to resources.
            '';
          };

          extraArguments = mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "-46";
            description = ''
              Extra arguments for service.
              Consult "Options" section in [documentation](https://github.com/z3APA3A/3proxy/wiki/3proxy.cfg) for available arguments.
            '';
          };

          extraConfig = mkOption {
            type = lib.types.nullOr lib.types.lines;
            default = null;
            description = ''
              Extra configuration for service. Use this to configure things like bandwidth limiter or ACL-based redirection.
              Consult [documentation](https://github.com/z3APA3A/3proxy/wiki/3proxy.cfg) for available options.
            '';
          };
        };
      }));
      default = { };
      example = lib.literalExpression ''
        {
          "http-proxy" = {
            enable = true;
            type = "proxy";
            bindAddress = "192.168.1.24";
            bindPort = 3128;
            auth = [ "none" ];
          };
          "socks-proxy" = {
            enable = true;
            type = "socks";
            bindAddress = "172.17.0.1";
            bindPort = 1080;
            auth = [ "strong" ];
          };
        }
      '';
      description = ''
        Use this option to define 3proxy services.
      '';
    };

    usersFile = mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = "/var/lib/3proxy/3proxy.passwd";
      description = ''
        Load users and passwords from this file.

        Example users file with plain-text passwords:

        ```
          test1:CL:password1
          test2:CL:password2
        ```

        Example users file with md5-crypted passwords:

        ```
          test1:CR:$1$tFkisVd2$1GA8JXkRmTXdLDytM/i3a1
          test2:CR:$1$rkpibm5J$Aq1.9VtYAn0JrqZ8M.1ME.
        ```

        You can generate md5-crypted passwords via <https://unix4lyfe.org/crypt/>
        Note that htpasswd tool generates incompatible md5-crypted passwords.
        Consult [documentation](https://github.com/z3APA3A/3proxy/wiki/How-To-%28incomplete%29#USERS) for more information.
      '';
    };

    denyPrivate = mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to deny access to private IP ranges including loopback.
      '';
    };

    privateRanges = mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "0.0.0.0/8"
        "127.0.0.0/8"
        "10.0.0.0/8"
        "100.64.0.0/10"
        "172.16.0.0/12"
        "192.168.0.0/16"
        "::"
        "::1"
        "fc00::/7"
      ];
      description = ''
        What IP ranges to deny access when denyPrivate is set to true.
      '';
    };

    resolution = mkOption {
      type = lib.types.submodule {
        options = {
          nserver = mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            example = [
              "127.0.0.53"
              "192.168.1.3:5353/tcp"
            ];
            description = ''
              List of nameservers to use.

              Up to 5 nservers may be specified. If no nserver is configured,
              default system name resolution functions are used.
            '';
          };
          nscache = mkOption {
            type = lib.types.int;
            default = 65535;
            description = "Set name cache size for IPv4.";
          };
          nscache6 = mkOption {
            type = lib.types.int;
            default = 65535;
            description = "Set name cache size for IPv6.";
          };
          nsrecord = mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
            example = lib.literalExpression ''
              {
                "files.local" = "192.168.1.12";
                "site.local" = "192.168.1.43";
              }
            '';
            description = "Adds static nsrecords.";
          };
        };
      };
      default = { };
      description = ''
        Use this option to configure name resolution and DNS caching.
      '';
    };

    extraConfig = mkOption {
      type = lib.types.nullOr lib.types.lines;
      default = null;
      description = ''
        Extra configuration, appended to the 3proxy configuration file.
        Consult [documentation](https://github.com/z3APA3A/3proxy/wiki/3proxy.cfg) for available options.
      '';
    };

    user = mkOption {
      type = types.str;
      description = ''
        User under which to run the 3proxy server.
      '';
      default = defaultUser;
    };

    group = mkOption {
      type = types.str;
      description = ''
        Group under which to run the 3proxy server.
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
          # shellcheck disable=SC2174
          ${pkgs.coreutils}/bin/mkdir -p -m 0750 ${homeDir}/log
          ${pkgs.coreutils}/bin/chown ${cfg.user}:${cfg.group} ${homeDir}
          ${pkgs.coreutils}/bin/chown ${cfg.user}:${cfg.group} ${homeDir}/log
        '';
      };
    };

    launchd.daemons = mapAttrs'
      (name: conf: nameValuePair (proxyName name) (
        let
          serverConf = conf // { inherit name; };
          configFile = generateConfig serverConf;
        in
        {
          command = "${pkg}/bin/3proxy ${configFile}";
          serviceConfig = {
            GroupName = cfg.group;
            Label = "dev.cobi.3proxy.${proxyName name}";
            RunAtLoad = true;
            StandardOutPath = "${homeDir}/log/${proxyName name}.out";
            StandardErrorPath = "${homeDir}/log/${proxyName name}.err";
            UserName = cfg.user;
            WorkingDirectory = homeDir;
            KeepAlive = true;
          };
        }
      ))
      enabledServers;

    users = mkIf (cfg.user == defaultUser) {
      users."${cfg.user}" = {
        inherit (config.users.groups."${cfg.user}") gid;
        createHome = false;
        description = "3proxy service user";
        home = homeDir;
        shell = "/bin/bash";
        uid = lib.mkDefault 802;
      };
      knownUsers = [ "${cfg.user}" ];
      groups."${cfg.user}" = {
        gid = lib.mkDefault 802;
        description = "3proxy service user group";
      };
      knownGroups = [ "${cfg.user}" ];
    };
  };
}
