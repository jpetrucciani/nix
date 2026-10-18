{ lib, mkG7cBinaryRelease }:
let
  release = lib.importJSON ./tumbler.json;
in
mkG7cBinaryRelease {
  pname = "tumbler";
  inherit (release) hashes version;
  dataFile = "pkgs/server/tumbler.json";
  installCompletions = false;

  meta = {
    description = "tumbler runs coding agents in rootless podman for a bezel control plane";
    homepage = "https://bz.cobi.dev";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}
