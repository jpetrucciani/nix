#!/bin/bash
# shellcheck disable=all

{ # Prevent execution if this script was only partially downloaded
  sh <(curl -L https://nixos.org/nix/install) --daemon

  # configure nix, adding higher concurrency and some features that speed things up
  mkdir -p ~/.config/nix/
  echo -e 'max-jobs = auto\nexperimental-features = nix-command flakes' >>~/.config/nix/nix.conf

  . $HOME/.nix-profile/etc/profile.d/nix.sh
  # install direnv, nix-direnv
  nix-env -f 'https://github.com/jpetrucciani/nix/archive/main.tar.gz' -iA direnv nix-direnv
  echo "source $HOME/.nix-profile/share/nix-direnv/direnvrc" >~/.direnvrc

  echo ". $HOME/.nix-profile/etc/profile.d/nix.sh" >>~/.bashrc
  echo 'eval "$(direnv hook bash)"' >>~/.bashrc
  echo ". $HOME/.nix-profile/etc/profile.d/nix.sh" >>~/.zshrc
  echo 'eval "$(direnv hook zsh)"' >>~/.zshrc
} # End of wrapping
