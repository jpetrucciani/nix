final: prev:
let
  flags = "--no-link --print-out-paths --extra-experimental-features nix-command --extra-experimental-features flakes";
in
rec {
  inherit (prev) _ nvd writeBashBinChecked;
  inherit (prev.hax) isDarwin isLinux;

  ### GENERAL STUFF
  _nixos-switch = { host }: writeBashBinChecked "switch" ''
    toplevel="$(nix build ${flags} ~/cfg#nixosConfigurations.${host}.config.system.build.toplevel)"
    if [[ $(realpath /run/current-system) != "$toplevel" || "$POG_FORCE" == "1" ]];then
      ${nvd}/bin/nvd diff /run/current-system "$toplevel"
      sudo nix-env -p /nix/var/nix/profiles/system --set "$toplevel"
      sudo "$toplevel"/bin/switch-to-configuration switch
    fi
  '';
  _nix-darwin-switch = { host }:
    writeBashBinChecked "switch" ''
      profile=/nix/var/nix/profiles/system
      toplevel="$(nix build ${flags} ~/cfg#darwinConfigurations.${host}.system)"
      if [[ $(realpath "$profile") != "$toplevel" ]];then
        ${nvd}/bin/nvd diff "$profile" "$toplevel"
        sudo -H nix-env -p "$profile" --set "$toplevel"
        "$toplevel"/activate-user
        sudo "$toplevel"/activate
      fi
    '';
  _hms = {
    default = ''
      ${_.git} -C ~/cfg/ pull origin main
      home-manager switch
    '';
    nixOS = ''
      ${_.git} -C ~/cfg/ pull origin main
      "$(nix-build --no-link --expr 'with import ~/cfg {}; _nixos-switch' --argstr host "$(machine-name)")"/bin/switch
    '';
    darwin = ''
      ${_.git} -C ~/cfg/ pull origin main
      "$(nix-build --no-link --expr 'with import ~/cfg {}; _nix-darwin-switch' --argstr host "$(machine-name)")"/bin/switch
    '';
    switch = if isLinux then _hms.nixOS else (if isDarwin then _hms.darwin else _hms.default);
  };

  hms = writeBashBinChecked "hms" _hms.switch;

  # fix for getting yank working on darwin
  yank = prev.yank.overrideAttrs (attrs: {
    makeFlags = if isDarwin then [ "YANKCMD=/usr/bin/pbcopy" ] else attrs.makeFlags;
  });

  # fix for python3Packages.ray
  py-spy = prev.py-spy.overrideAttrs (old: {
    doCheck = false;
  });
}
