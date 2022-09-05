{ config, pkgs, lib, ... }:
let
  base_dir = "/var/lib/valheim";
in
{
  users.users.valheim = {
    # Valheim puts save data in the home directory.
    home = base_dir;
    group = "valheim";
    createHome = true;
    isSystemUser = true;
  };
  users.groups.valheim = { };

  systemd.services.valheim = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      EnvironmentFile = "/etc/default/valheim";
      ExecStartPre = ''
        ${pkgs.steamcmd}/bin/steamcmd \
          +force_install_dir $STATE_DIRECTORY \
          +login anonymous \
          +app_update 896660 \
          +quit

          # Fix a missplaced library
          mkdir -p ~/.steam/sdk64
          ln ${base_dir}/linux64/steamclient.so ~/.steam/sdk64
      '';
      ExecStart = ''
        ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 ./valheim_server.x86_64 \
          -name "memeworld" \
          -port 2456 \
          -world "Dedicated" \
          -password "$VALHEIM_PASSWORD" \
          -public 1
      '';
      Nice = "-5";
      Restart = "always";
      StateDirectory = "valheim";
      User = "valheim";
      WorkingDirectory = base_dir;
    };
    environment = {
      # linux64 directory is required by Valheim.
      LD_LIBRARY_PATH = "linux64:${pkgs.glibc}/lib";
    };
  };
}
