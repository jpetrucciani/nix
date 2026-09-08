{ lib, mkG7cBinaryRelease }:
let
  release = lib.importJSON ./viz.json;
in
mkG7cBinaryRelease {
  pname = "viz";
  inherit (release) hashes version;
  dataFile = "pkgs/server/viz.json";

  meta = {
    description = "experimental markdown and Mermaid scratch pad server";
    homepage = "https://github.com/jpetrucciani/viz";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
  };
}
