{ config, lib, pkgs, ... }:

# FROM: https://git.sr.ht/~bwolf/miniflux.nix
# Database preparation:
#
# $ sudo -u postgres -i
#
# $ createuser -P miniflux
# Enter password for new role: ******
# Enter it again: ******
#
# $ createdb -O miniflux miniflux
#
# $ psql miniflux -c 'create extension hstore'
#
# Or alternatively by using SQL:
#
# CREATE ROLE miniflux WITH LOGIN ENCRYPTED PASSWORD 'password';
# CREATE DATABASE miniflux OWNER miniflux;
# \connect miniflux
# CREATE EXTENSION hstore;

with lib;
let
  cfg = config.services.minifluxng;
  inherit (lib.types) str;

  database-url =
    "host=${cfg.dbHost} user=${cfg.dbUser} dbname=${cfg.dbName} sslmode=${cfg.dbSslMode}";

  miniflux-migrate = pkgs.writeShellScriptBin "miniflux-migrate" ''
    ${cfg.package}/bin/miniflux -migrate
  '';

  miniflux-create-admin = pkgs.writeShellScriptBin "miniflux-create-admin" ''
    ${cfg.package}/bin/miniflux -create-admin
  '';

  miniflux = pkgs.writeShellScriptBin "miniflux" ''
    ${cfg.package}/bin/miniflux
  '';

  miniflux-reset-feed-errors =
    pkgs.writeShellScriptBin "miniflux-reset-feed-errors" ''
      ${cfg.package}/bin/miniflux -reset-feed-errors
    '';

  # Hardening.
  hardening_config = {
    CapabilityBoundingSet = null;
    LockPersonality = true;
    MemoryDenyWriteExecute = true;
    NoNewPrivileges = true;
    PrivateDevices = true;
    PrivateUsers = true;
    ProcSubset = "pid";
    ProtectClock = true;
    ProtectControlGroups = true;
    ProtectHome = true;
    ProtectHostname = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    ProtectProc = "invisible";
    ProtectSystem = "strict";
    RemoveIPC = true;
    RestrictAddressFamilies = "AF_INET AF_INET6";
    RestrictNamespaces = true;
    RestrictRealtime = true;
    SystemCallArchitectures = "native";
    SystemCallFilter = [ "@system-service" "~@privileged" ];
    UMask = "0077";
  };
in
{
  options.services.minifluxng = {
    enable = mkEnableOption "Miniflux NG";
    envFilePath = mkOption {
      type = str;
      default = "/etc/default/miniflux";
    };
    enableDebugMode =
      mkEnableOption "Enable debug mode, which increases log level";

    package = mkOption {
      type = types.package;
      default = pkgs.miniflux;
      example = literalExpression "pkgs.miniflux";
      description = ''
        Miniflux package to use.
      '';
    };

    dbHost = mkOption {
      type = types.str;
      default = "localhost";
      description = "The PostgreSQL hostname or IP.";
    };

    dbUser = mkOption {
      type = types.str;
      default = "miniflux";
      description = "PostgreSQL Database user.";
    };

    dbName = mkOption {
      type = types.str;
      default = "miniflux";
      description = "PostgreSQL Database name.";
    };

    dbSslMode = mkOption {
      type = types.enum [ "disable" "allow" "prefer" "require" ];
      default = "disable";
      description = "PostgreSQL SSL mode.";
    };

    enableOidc = mkEnableOption "Enable OpenID Connect";

    oidcClientId = mkOption {
      type = types.str;
      description = ''
        OpenID Connect client ID. A Client secret is required
        for OpenID Connect.
      '';
    };

    oidcRedirectUrl = mkOption {
      type = types.str;
      description = "OpenID Connect redirect URL.";
      example = ''
        https://my.domain.tld/oauth2/oidc/callback
      '';
    };

    oidcDiscoveryEndpoint = mkOption {
      type = types.str;
      description = ''
        OpenID Connect discovery URL. Note that Miniflux
        appends .well-known/openid-configuration to this URI,
        so be sure to omit that. Please further note that
        this URI needs to be the same as the discovery URI
        returns as issuer.
      '';
      example = ''
        https://id.domain.tld/dex
      '';
    };

    enableOidcUserCreation = mkEnableOption ''
      Automatically create a user for successfully authenticated
      OpenID Connect users.
    '';

    listenAddress = mkOption {
      type = types.str;
      default = "127.0.0.1:8088";
      description = ''
        Miniflux listen address, which is a Go like listen address
        consisting of the IP address followed by ':' and the port.
      '';
      example = "::1:8088";
    };

    tlsCertificateFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to TLS certificate.";
    };

    tlsKeyFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to TLS key.";
    };

    baseUrl = mkOption {
      type = types.nullOr types.str;
      default = null;
      description =
        "Base URL to generate HTML links and base path for cookies.";
    };

    enableMetrics = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Enable metrics collection. It exposes a /metrics end-point.
      '';
    };

    metricsAllowedNetworks = mkOption {
      type = types.str;
      default = "127.0.0.1/8,100.64.0.0/10";
      description = ''
        List of networks allowed to access the /metrics endpoint
        (comma-separated values). Default: 127.0.0.1/8,100.64.0.0/10.
      '';
    };
  };

  ### Implementation
  config = mkIf cfg.enable {
    systemd.services = {
      minifluxng-migrate = {
        description = "Miniflux migrate database";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        environment.DATABASE_URL = database-url;
        # TODO max runtime, if over then kill
        serviceConfig = {
          Type = "oneshot";
          DynamicUser = true;
          RuntimeDirectory = "miniflux"; # Creates /run/miniflux.
          EnvironmentFile = cfg.envFilePath;
          ExecStart = ''
            ${miniflux-migrate}/bin/miniflux-migrate
          '';
        } // hardening_config;
      };

      minifluxng-create-admin = {
        description = "Miniflux create admin";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" "minifluxng-migrate.service" ];
        environment.DATABASE_URL = database-url;
        # TODO max runtime, if over then kill
        serviceConfig = {
          Type = "oneshot";
          DynamicUser = true;
          RuntimeDirectory = "miniflux"; # Creates /run/miniflux.
          EnvironmentFile = cfg.envFilePath;
          ExecStart = ''
            ${miniflux-create-admin}/bin/miniflux-create-admin
          '';
        } // hardening_config;
      };

      minifluxng = {
        description = "Miniflux";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" "minifluxng-create-admin.service" ];
        environment = {
          DATABASE_URL = database-url;
          DEBUG = optionalString cfg.enableDebugMode "1";
          LISTEN_ADDR = cfg.listenAddress;
          METRICS_COLLECTOR = if cfg.enableMetrics then "1" else "0";
          METRICS_ALLOWED_NETWORKS = cfg.metricsAllowedNetworks;
          OAUTH2_CLIENT_ID = optionalString cfg.enableOidc cfg.oidcClientId;
          OAUTH2_PROVIDER = optionalString cfg.enableOidc "oidc";
          OAUTH2_OIDC_DISCOVERY_ENDPOINT =
            optionalString cfg.enableOidc cfg.oidcDiscoveryEndpoint;
          OAUTH2_REDIRECT_URL = optionalString cfg.enableOidc cfg.oidcRedirectUrl;
          OAUTH2_USER_CREATION = if cfg.enableOidcUserCreation then "1" else "0";
        } // lib.optionalAttrs (cfg.baseUrl != null) { BASE_URL = cfg.baseUrl; };
        # TODO automatic restart on failure
        serviceConfig = {
          Type = "simple";
          DynamicUser = true;
          RuntimeDirectory = "miniflux"; # Creates /run/miniflux.
          EnvironmentFile = cfg.envFilePath;
          ExecStart = ''
            ${miniflux}/bin/miniflux
          '';

        } // hardening_config;
      };

      minifluxng-reset-feed-errors = {
        description = "Miniflux reset feed errors";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" "minifluxng.service" ];
        environment.DATABASE_URL = database-url;
        startAt = "00/4:00"; # Every four hours.
        serviceConfig = {
          Type = "oneshot";
          DynamicUser = true;
          RuntimeDirectory = "miniflux"; # Creates /run/miniflux.
          EnvironmentFile = cfg.envFilePath;
          ExecStart = ''
            ${miniflux-reset-feed-errors}/bin/miniflux-reset-feed-errors
          '';
        } // hardening_config;
      };
    };
  };
}
