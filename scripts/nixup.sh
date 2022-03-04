#!/bin/sh

{ # Prevent execution if this script was only partially downloaded
curl -L https://nixos.org/nix/install | sh

# configure nix, adding higher concurrency and some features that speed things up
mkdir -p ~/.config/nix/
echo -e 'max-jobs = auto\ntarball-ttl = 0\nexperimental-features = nix-command flakes' >>~/.config/nix/nix.conf

# install direnv and nix-direnv
nix-env -i direnv nix-direnv cachix

echo 'eval "$(direnv hook bash)"' >>~/.bashrc
echo 'eval "$(direnv hook zsh)"' >>~/.zshrc
} # End of wrapping
