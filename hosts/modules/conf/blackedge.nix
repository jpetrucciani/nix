{ pkgs, config, lib, ... }:
let
  inherit (lib) mkIf mkEnableOption mkOption concatStringsSep;
  inherit (lib.types) bool str listOf;
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
    tls = mkOption {
      type = bool;
      default = false;
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
    extraSssd = mkOption {
      type = str;
      default = "";
    };
  };
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      realmd
      sssd
      adcli
      oddjob
      samba
      krb5
    ];
    systemd.services.realmd.environment = {
      REALMD_CACHE_DIR = "/var/cache/realmd";
    };
    # hack to get ldap login working
    systemd.tmpfiles.rules = [
      "L /bin/bash - - - - /run/current-system/sw/bin/bash"
      "L /usr/sbin/oddjobd - - - - ${pkgs.oddjob}/bin/oddjobd"
      "L /usr/libexec/oddjob/mkhomedir - - - - ${pkgs.oddjob}/libexec/oddjob/mkhomedir"
      "L /usr/sbin/sssd - - - - ${pkgs.sssd}/bin/sssd"
      "L /usr/sbin/adcli - - - - ${pkgs.adcli}/bin/adcli"
      "d /var/cache/realmd 0755 root root -"
    ];
    security = {
      polkit.enable = true;
      pam.services.systemd-user.makeHomeDir = true;
      sudo.extraRules = [
        { groups = cfg.allowedGroups; commands = [{ command = "ALL"; options = [ "NOPASSWD" ]; }]; }
      ];
      krb5 = {
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
            permitted_enctypes = "aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96 aes256-cts-hmac-sha256-128 aes128-cts-hmac-sha256-128";
            default_tkt_enctypes = "aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96";
            default_tgs_enctypes = "aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96";
          };
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
        AllowGroups wheel ${concatStringsSep " " (map lib.toLower cfg.allowedGroups)}
      '';
    };
    services = {
      realmd = {
        enable = true;
      };
      sssd = {
        enable = true;
        sshAuthorizedKeysIntegration = true;
        config = ''
          [sssd]
          config_file_version = 2
          services = nss, pam, ssh, sudo
          domains = ${cfg.domain}

          [domain/${cfg.domain}]
          access_provider = ad
          ad_domain = ${cfg.domain}
          ad_server = ${cfg.adDomain}
          auth_provider = ad
          fallback_homedir = /home/%u
          id_provider = ad
          krb5_realm = ${cfg.krbDomain}
          ldap_id_mapping = True
          ldap_referrals = false
          ldap_schema = AD
          ldap_uri = ldap${if cfg.tls then "s" else ""}://${cfg.adDomain}
          ad_use_ldaps = True
          ldap_tls_cacert = ${cfg.caPath}
          simple_allow_groups = ${concatStringsSep "," cfg.allowedGroups}
          ldap_user_name = sAMAccountName
          ldap_user_extra_attrs = altSecurityIdentities:altSecurityIdentities
          ldap_user_ssh_public_key = altSecurityIdentities
          ldap_use_tokengroups = True
          use_fully_qualified_names = False
          ${cfg.extraSssd}
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
