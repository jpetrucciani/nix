final: prev:
with prev;
with builtins; rec {
  inherit (prev.hax) isM1 isLinux isDarwin isOldMac isNixOS isAndroid isUbuntu isNixDarwin;

  nd = fromJSON (readFile ../sources/darwin.json);
  nix-darwin = fetchFromGitHub {
    inherit (nd) rev sha256;
    owner = "LnL7";
    repo = "nix-darwin";
  };

  nix2container-pin = fromJSON (readFile ../sources/nix2container.json);
  nix2container = import
    (fetchFromGitHub {
      inherit (nix2container-pin) rev sha256;
      owner = "nlewo";
      repo = "nix2container";
    })
    { pkgs = prev; };

  devenv-pin = fromJSON (readFile ../sources/devenv.json);
  devenv = import (fetchFromGitHub {
    inherit (devenv-pin) rev sha256;
    owner = "cachix";
    repo = "devenv";
  });

  ### GENERAL STUFF
  _nixos-switch = { host }: writeBashBinChecked "switch" ''
    set -eo pipefail
    toplevel=$(nix-build --no-link --expr 'with import ~/cfg {}; (nixos ~/cfg/hosts/${host}/configuration.nix).toplevel')
    if [[ $(realpath /run/current-system) != "$toplevel" || "$POG_FORCE" == "1" ]];then
      ${nvd}/bin/nvd diff /run/current-system "$toplevel"
      sudo nix-env -p /nix/var/nix/profiles/system --set "$toplevel"
      sudo "$toplevel"/bin/switch-to-configuration switch
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
      nix_darwin_path="$(nix-build --no-link --expr 'with import ~/.config/nixpkgs {}; nix-darwin')"
      darwin-rebuild switch -I darwin="$nix_darwin_path" -I darwin-config="$NIXDARWIN_CONFIG"
    '';
    switch =
      if
        isNixOS then _hms.nixOS else (if isNixDarwin then _hms.darwin else _hms.default);
  };

  hms = writeBashBinChecked "hms" _hms.switch;

  yank = prev.yank.overrideAttrs (attrs: {
    makeFlags = if isDarwin then [ "YANKCMD=/usr/bin/pbcopy" ] else attrs.makeFlags;
  });
}
