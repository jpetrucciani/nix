{ pkgs, ... }:
let
  environment = (import /home/jacobi/dev/api/default.nix) { };
in
{
  systemd.services.api = {
    wantedBy = [ "multi-user.target" ];
    script = ''
      cd /home/jacobi/dev/api
      ${environment}/bin/uvicorn api:API \
        --host 0.0.0.0 \
        --port 10000
    '';
  };
}
