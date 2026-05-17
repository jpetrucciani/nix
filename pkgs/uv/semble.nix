# [semble](https://github.com/MinishLab/semble) is Fast and Accurate Code Search for Agents
{ lib, uv-nix, version ? "0.1.7", lockHash ? "sha256-vDHt8+8+SWxE2IIL/ZWqsbqk1v6wcEED9KhHfwxzmR8=", includePin ? false }:
let
  name = "semble";
in
uv-nix.buildUvPackage rec {
  inherit version lockHash includePin;
  pname = name;

  lockUrl = "https://static.g7c.us/lock/uv/semble/${version}.lock";

  meta = {
    description = "Fast and Accurate Code Search for Agents";
    homepage = "https://github.com/MinishLab/semble";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = name;
    skipBuild = true; # don't ever build this on github actions - it's quite heavy!
  };
}
