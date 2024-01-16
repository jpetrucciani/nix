{ config, lib, ... }:
let
  inherit (lib) mkIf mkEnableOption mkOption concatStringsSep;
  inherit (lib.types) str listOf;
  cfg = config.conf.blackedge;
in
{
  options.conf.blackedge = {
    enable = mkEnableOption "blackedge";
    bindUser = mkOption {
      type = str;
      default = "adservice";
    };
    domain = mkOption {
      type = str;
      default = "blackedge.local";
    };
    adDomain = mkOption {
      type = str;
      default = "cy1-dc-01.blackedge.local";
    };
    krbDomain = mkOption {
      type = str;
      default = "BLACKEDGE.LOCAL";
    };
    allowedGroups = mkOption {
      type = listOf str;
      default = [ "Blackedge_Dev_Security" ];
    };
    envFilePath = mkOption {
      type = str;
      default = "/etc/default/sssd";
    };
    caPath = mkOption {
      type = str;
      default = "/etc/default/ldap_ca.pem";
    };
  };
  config = mkIf cfg.enable {
    # hack to get ldap login working
    systemd.tmpfiles.rules = [
      "L /bin/bash - - - - /run/current-system/sw/bin/bash"
    ];
    security.pam.services.systemd-user.makeHomeDir = true;
    security.sudo.extraRules = [
      { groups = cfg.allowedGroups; commands = [{ command = "ALL"; options = [ "NOPASSWD" ]; }]; }
    ];
    security.krb5 = {
      enable = true;
      settings = {
        realms = {
          ${cfg.krbDomain} = { };
        };
        domain_realm = {
          ${cfg.domain} = cfg.krbDomain;
          ".${cfg.domain}" = cfg.krbDomain;
        };
        libdefaults = {
          default_realm = cfg.krbDomain;
          dns_lookup_realm = false;
          ticket_lifetime = "24h";
          renew_lifetime = "7d";
          forwardable = true;
          default_ccache_name = "KEYRING:persistent:%{uid}";
          rdns = false;
        };
      };
    };

    # allow us to specify the location of the ldap AD service account password file
    systemd.services.sssd.serviceConfig.EnvironmentFile = cfg.envFilePath;

    services.openssh = {
      settings = {
        PasswordAuthentication = lib.mkForce true;
        X11Forwarding = lib.mkForce false;
      };
      extraConfig = ''
        AllowGroups wheel ${concatStringsSep " " cfg.allowedGroups}
      '';
    };
    services = {
      sssd = {
        enable = true;
        config = let suffix = "ou=Users,ou=blackedge,dc=blackedge,dc=local"; in ''
          [sssd]
          config_file_version = 2
          services = nss, pam, ssh
          domains = ${cfg.domain}

          [domain/${cfg.domain}]
          access_provider = simple
          ad_domain = ${cfg.domain}
          ad_server = ${cfg.adDomain}
          auth_provider = ldap
          fallback_homedir = /home/%u
          id_provider = ldap
          krb5_realm = ${cfg.krbDomain}
          ldap_default_authtok = $LDAP_BIND_PW
          ldap_default_authtok_type = password
          ldap_default_bind_dn = ${cfg.bindUser}
          ldap_group_search_base = ${suffix}
          ldap_id_mapping = True
          ldap_referrals = false
          ldap_schema = AD
          ldap_search_base = ${suffix}
          ldap_uri = ldap://${cfg.adDomain}
          ldap_user_search_base = ${suffix}
          ad_use_ldaps = True
          ldap_tls_cacert = ${cfg.caPath}
          simple_allow_groups = ${concatStringsSep "," cfg.allowedGroups}
        '';
      };
      nscd.config = ''
        enable-cache hosts yes
        enable-cache passwd no
        enable-cache group no
        enable-cache netgroup no
        enable-cache services no
      '';
    };
  };
}
