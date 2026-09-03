# This overlay provides more packages and scripts for use in my setup. This is also used in my repo's modified comma, exposing the binaries and scripts in this overlay directly through comma.
final: prev:
let
  inherit (final) coreutils diffutils git nix nvd machines;
  inherit (final.lib) listToAttrs;
  inherit (final.hax) writeBashBinChecked;
  nbuild = "${nix}/bin/nix build --no-link --print-out-paths --extra-experimental-features nix-command --extra-experimental-features flakes";
  parseAction = ''
    set -euo pipefail

    usage() {
      printf 'Usage: %s [build|diff|switch]\n' "$0"
    }

    if [[ "$#" -gt 1 ]]; then
      usage >&2
      exit 2
    fi

    action="''${1:-switch}"
    case "$action" in
      build | diff | switch) ;;
      -h | --help | help)
        usage
        exit 0
        ;;
      *)
        printf 'unknown action: %s\n' "$action" >&2
        usage >&2
        exit 2
        ;;
    esac
  '';
  _nixos-switch = host: writeBashBinChecked "switch" ''
    ${parseAction}

    current=/run/current-system
    toplevel="$(${nbuild} "$HOME/cfg#nixosConfigurations.${host}.config.system.build.toplevel")"

    if [[ "$action" == "build" ]]; then
      printf '%s\n' "$toplevel"
      exit 0
    fi

    if [[ "$action" == "diff" ]]; then
      printf 'System closure changes:\n'
      ${nvd}/bin/nvd diff "$current" "$toplevel"
      printf '\nSystemd activation plan:\n'
      sudo "$toplevel"/bin/switch-to-configuration dry-activate
      exit 0
    fi

    switch_action=switch
    if [[ "''${POG_BOOT_ONLY:-}" == "1" ]];then
      switch_action=boot
    fi
    if [[ $(${coreutils}/bin/realpath "$current") != "$toplevel" || "''${POG_FORCE:-}" == "1" ]];then
      ${nvd}/bin/nvd diff "$current" "$toplevel"
      sudo ${nix}/bin/nix-env -p /nix/var/nix/profiles/system --set "$toplevel"
      sudo "$toplevel"/bin/switch-to-configuration "$switch_action"
    fi
  '';
  _darwin-switch = host:
    writeBashBinChecked "switch" ''
      ${parseAction}

      profile=/nix/var/nix/profiles/system
      toplevel="$(${nbuild} "$HOME/cfg#darwinConfigurations.${host}.system")"

      if [[ "$action" == "build" ]]; then
        printf '%s\n' "$toplevel"
        exit 0
      fi

      if [[ "$action" == "diff" ]]; then
        printf 'System closure changes:\n'
        ${nvd}/bin/nvd diff "$profile" "$toplevel"

        printf '\nLaunchd service definition changes:\n'
        launchd_changed=0
        for relative_path in Library/LaunchAgents Library/LaunchDaemons user/Library/LaunchAgents; do
          diff_status=0
          ${diffutils}/bin/diff --brief --new-file --recursive \
            "$profile/$relative_path" "$toplevel/$relative_path" || diff_status=$?
          if [[ "$diff_status" -gt 1 ]]; then
            exit "$diff_status"
          fi
          if [[ "$diff_status" -eq 1 ]]; then
            launchd_changed=1
          fi
        done
        if [[ "$launchd_changed" -eq 0 ]]; then
          printf 'No launchd service definition changes.\n'
        fi
        exit 0
      fi

      if [[ $(${coreutils}/bin/realpath "$profile") != "$toplevel" || "''${POG_FORCE:-}" == "1" ]];then
        ${nvd}/bin/nvd diff "$profile" "$toplevel"
        sudo -H ${nix}/bin/nix-env -p "$profile" --set "$toplevel"
        sudo "$toplevel"/activate
      fi
    '';
in
{
  hmx = (listToAttrs (map (name: { inherit name; value = _nixos-switch name; }) machines.nixos)) //
    (listToAttrs (map (name: { inherit name; value = _darwin-switch name; }) machines.darwin));
  hms = writeBashBinChecked "hms" ''
    ${parseAction}

    ${git}/bin/git -C ~/cfg/ pull origin main
    host="$(machine-name)"
    "$(${nbuild} "$HOME/cfg#hmx.$host")"/bin/switch "$action"
  '';
}
