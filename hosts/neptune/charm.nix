{ pkgs, ... }:
let
  host = "charm.cobi.dev";
  base_dir = "/opt/charm";
in
{
  systemd.services.charm = {
    wantedBy = [ "multi-user.target" ];
    script = ''
      export CHARM_SERVER_BIND_ADDRESS="127.0.0.1"
      export CHARM_SERVER_PUBLIC_URL="${host}"
      export CHARM_SERVER_DATA_DIR="${base_dir}/data"
      ${pkgs.charm}/bin/charm serve
    '';
  };
}
