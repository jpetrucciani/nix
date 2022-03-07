#!/bin/sh

{ # Prevent execution if this script was only partially downloaded
curl -L https://nixos.org/nix/install | sh

# configure nix, adding higher concurrency and some features that speed things up
mkdir -p ~/.config/nix/
echo -e 'max-jobs = auto\nexperimental-features = nix-command flakes' >>~/.config/nix/nix.conf

# install direnv, nix-direnv, and cachix
nix-env -i direnv nix-direnv cachix
nix-env --set-flag priority 10 direnv
nix-env --set-flag priority 10 nix-direnv
nix-env --set-flag priority 10 cachix

echo 'eval "$(direnv hook bash)"' >>~/.bashrc
echo 'eval "$(direnv hook zsh)"' >>~/.zshrc
} # End of wrapping
