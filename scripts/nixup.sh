#!/usr/bin/env bash
# shellcheck disable=SC2016

{ # Prevent execution if this script was only partially downloaded
  set -eo pipefail

  sh <(curl -fsSL https://nixos.org/nix/install) --daemon

  # configure nix, adding higher concurrency and some features that speed things up
  mkdir -p ~/.config/nix/
  printf 'max-jobs = auto\nexperimental-features = nix-command flakes\n' >>~/.config/nix/nix.conf

  nix_profile=/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  # shellcheck source=/dev/null
  . "$nix_profile"

  # install direnv, nix-direnv
  nix-env -f 'https://github.com/jpetrucciani/nix/archive/main.tar.gz' -iA direnv nix-direnv
  echo "source $HOME/.nix-profile/share/nix-direnv/direnvrc" >~/.direnvrc

  echo ". $nix_profile" >>~/.bashrc
  echo 'eval "$(direnv hook bash)"' >>~/.bashrc
  echo ". $nix_profile" >>~/.zshrc
  echo 'eval "$(direnv hook zsh)"' >>~/.zshrc
} # End of wrapping
