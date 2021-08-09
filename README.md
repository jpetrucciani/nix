# nix

[![uses nix](https://img.shields.io/badge/uses-nix-%237EBAE4)](https://nixos.org/)

_my nixpkgs folder_

## install

```bash
# install nix

## linux
curl -L https://nixos.org/nix/install | sh

## mac
sh <(curl -L https://nixos.org/nix/install) --darwin-use-unencrypted-nix-store-volume

# configure nix
mkdir -p ~/.config/nix/
echo 'max-jobs = auto' >>~/.config/nix/nix.conf

# install home manager
echo "export NIX_PATH=/nix/var/nix/profiles/per-user/$USER/channels:nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixpkgs:/nix/var/nix/profiles/per-user/root/channels" | sudo tee -a /etc/profile
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install

# pull repo into ~/.config/nixpkgs/
cd ~/.config/nixpkgs
rm home.nix
git clone https://github.com/jpetrucciani/nix.git .

# enable home-manager
home-manager switch
```
