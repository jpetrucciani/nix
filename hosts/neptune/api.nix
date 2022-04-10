{ pkgs, ... }:
let
  api = with pkgs; stdenv.mkDerivation {
    pname = "api";
    version = "0.1";
    src = /home/jacobi/dev/api;
    nativeBuildInputs = [ autoPatchelfHook ];
    installPhase = '' '';
  };
  environment = (import /home/jacobi/dev/api/default.nix) { };
in
{
  systemd.services.api = {
    wantedBy = [ "multi-user.target" ];
    script = ''
      cd /home/jacobi/dev/api
      ${environment}/bin/uvicorn api.api:API \
        --host 0.0.0.0 \
        --port 10000
    '';
  };
}
