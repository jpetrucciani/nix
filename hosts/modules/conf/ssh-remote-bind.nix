{ config, lib, pkgs, ... }:
let
  inherit (pkgs) openssh;
  inherit (lib) escapeShellArgs mkIf mkOption optionalString types;
  cfg = config.services.ssh-remote-bind;
in
{
  ###### interface
  options = {
    services.ssh-remote-bind = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable a remote bound port proxy
        '';
      };
      bindAll = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to request that the remote listener bind to all interfaces.
          The remote SSH server must permit this with its GatewayPorts setting.
        '';
      };

      persist = mkOption {
        type = types.bool;
        default = true;
        description = ''
          When this is set to true, the service will persistently attempt to
          reconnect at intervals whenever the port forwarding operation fails.
          This is the recommended behavior for reliable operation. If one finds
          oneself in an environment where this kind of behavior might draw the
          suspicion of a network administrator, it might be a good idea to
          set this option to false (or not use <literal>ssh-remote-bind</literal>
          at all).
        '';
      };

      localUser = mkOption {
        type = types.str;
        description = ''
          Local user to connect as (i.e. the user with password-less SSH keys).
        '';
      };

      remoteHostname = mkOption {
        type = types.str;
        description = ''
          The remote host to connect to. This should be the host outside of the
          firewall or NAT.
        '';
      };

      remotePort = mkOption {
        type = types.port;
        default = 22;
        description = ''
          The port on which to connect to the remote host via SSH protocol.
        '';
      };

      remoteUser = mkOption {
        type = types.str;
        description = ''
          The username to connect to the remote host as.
        '';
      };

      remoteBindPort = mkOption {
        type = types.port;
        default = 2222;
        description = ''
          The port to bind and listen to on the remote host.
        '';
      };

      localBindPort = mkOption {
        type = types.port;
        default = 2222;
        description = ''
          The port to listen to on the local host.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.ssh-remote-bind =
      {
        description = ''
          Reverse SSH tunnel as a service
        '';

        # FIXME: This isn't triggered until a reboot, and probably won't work between suspends.
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          User = cfg.localUser;
        } // (if cfg.persist then
          {
            # Restart every 10 seconds on failure
            RestartSec = 10;
            Restart = "on-failure";
          }
        else { }
        );

        script =
          let
            remoteForward = "${optionalString cfg.bindAll "*:"}${toString cfg.remoteBindPort}:localhost:${toString cfg.localBindPort}";
            sshArgs = [
              "-N"
              "-T"
              "-C"
              "-o"
              "ServerAliveInterval=30"
              "-o"
              "ExitOnForwardFailure=yes"
              "-R"
              remoteForward
              "-l"
              cfg.remoteUser
              "-p"
              (toString cfg.remotePort)
              cfg.remoteHostname
            ];
          in
          ''
            exec ${openssh}/bin/ssh ${escapeShellArgs sshArgs}
          '';
      };
  };
}
