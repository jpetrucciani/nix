{ lib, mkG7cBinaryRelease }:
let
  release = lib.importJSON ./titanite.json;
in
mkG7cBinaryRelease {
  pname = "titanite";
  inherit (release) hashes version;
  dataFile = "pkgs/server/titanite.json";

  meta = {
    description = "titanite is a policy-aware DNS service for homelabs and small production networks";
    homepage = "https://github.com/gemologic/titanite";
    platforms = [ "x86_64-linux" ];
  };
}
