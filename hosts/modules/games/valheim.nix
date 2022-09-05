{ config, pkgs, lib, ... }: {
  users.users.valheim = {
    # Valheim puts save data in the home directory.
    home = "/var/lib/valheim";
    group = "valheim";
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
      WorkingDirectory = "/var/lib/valheim";
    };
    environment = {
      # linux64 directory is required by Valheim.
      LD_LIBRARY_PATH = "linux64:${pkgs.glibc}/lib";
    };
  };
}
