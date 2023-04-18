final: prev:
with prev;
rec {
  inherit (prev.hax) isDarwin isNixOS;

  ### GENERAL STUFF
  _nixos-switch = { host }: writeBashBinChecked "switch" ''
    toplevel=$(nix-build --no-link --expr 'with import ~/cfg {}; (nixos ~/cfg/hosts/${host}/configuration.nix).toplevel')
    if [[ $(realpath /run/current-system) != "$toplevel" || "$POG_FORCE" == "1" ]];then
      ${nvd}/bin/nvd diff /run/current-system "$toplevel"
      sudo nix-env -p /nix/var/nix/profiles/system --set "$toplevel"
      sudo "$toplevel"/bin/switch-to-configuration switch
    fi
  '';
  _nix-darwin-switch = { host }:
    writeBashBinChecked "switch" ''
      profile=/nix/var/nix/profiles/system
      toplevel="$(nix build --no-link --print-out-paths ~/.config/nixpkgs#darwinConfigurations.${host}.system)"
      if [[ $(realpath "$profile") != "$toplevel" ]];then
        ${nvd}/bin/nvd diff "$profile" "$toplevel"
        sudo -H nix-env -p "$profile" --set "$toplevel"
        "$toplevel"/activate-user
        sudo "$toplevel"/activate
      fi
    '';
  _hms = {
    default = ''
      ${_.git} -C ~/.config/nixpkgs/ pull origin main
      home-manager switch
    '';
    nixOS = ''
      ${_.git} -C ~/cfg/ pull origin main
      "$(nix-build --no-link --expr 'with import ~/cfg {}; _nixos-switch' --argstr host "$HOSTNAME")"/bin/switch
    '';
    darwin = ''
      ${_.git} -C ~/.config/nixpkgs/ pull origin main
      "$(nix-build --no-link --expr 'with import ~/.config/nixpkgs {}; _nix-darwin-switch' --argstr host "$(machine-name)")"/bin/switch
    '';
    switch = if isNixOS then _hms.nixOS else (if isDarwin then _hms.darwin else _hms.default);
  };

  hms = writeBashBinChecked "hms" _hms.switch;

  yank = prev.yank.overrideAttrs (attrs: {
    makeFlags = if isDarwin then [ "YANKCMD=/usr/bin/pbcopy" ] else attrs.makeFlags;
  });
}
