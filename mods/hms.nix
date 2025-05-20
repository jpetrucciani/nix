# This overlay provides more packages and scripts for use in my setup. This is also used in my repo's modified comma, exposing the binaries and scripts in this overlay directly through comma.
final: prev:
let
  inherit (final) git nvd machines;
  inherit (final.lib) listToAttrs;
  inherit (final.hax) writeBashBinChecked;
  nbuild = "nix build --no-link --print-out-paths --extra-experimental-features nix-command --extra-experimental-features flakes";
  _nixos-switch = host: writeBashBinChecked "switch" ''
    toplevel="$(${nbuild} ~/cfg#nixosConfigurations.${host}.config.system.build.toplevel)"
    if [[ $(realpath /run/current-system) != "$toplevel" || "$POG_FORCE" == "1" ]];then
      ${nvd}/bin/nvd diff /run/current-system "$toplevel"
      sudo nix-env -p /nix/var/nix/profiles/system --set "$toplevel"
      sudo "$toplevel"/bin/switch-to-configuration switch
    fi
  '';
  _darwin-switch = host:
    writeBashBinChecked "switch" ''
      profile=/nix/var/nix/profiles/system
      toplevel="$(${nbuild} ~/cfg#darwinConfigurations.${host}.system)"
      if [[ $(realpath "$profile") != "$toplevel" || "$POG_FORCE" == "1" ]];then
        ${nvd}/bin/nvd diff "$profile" "$toplevel"
        sudo -H nix-env -p "$profile" --set "$toplevel"
        sudo "$toplevel"/activate
      fi
    '';
in
{
  hmx = (listToAttrs (map (name: { inherit name; value = _nixos-switch name; }) machines.nixos)) //
    (listToAttrs (map (name: { inherit name; value = _darwin-switch name; }) machines.darwin));
  hms = writeBashBinChecked "hms" ''
    ${git}/bin/git -C ~/cfg/ pull origin main
    "$(${nbuild} ~/cfg#hmx."$(machine-name)")"/bin/switch
  '';
}
