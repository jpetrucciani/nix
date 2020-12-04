# nix

[![uses nix](https://img.shields.io/badge/uses-nix-%237EBAE4)](https://nixos.org/)

_my nixpkgs folder_

## install

```bash
# install nix
sh <(curl -L https://nixos.org/nix/install) --daemon

# switch to nixos-unstable
nix-channel --add https://nixos.org/channels/nixos-unstable nixpkgs

# configure nix
mkdir -p ~/.config/nix/
echo 'max-jobs = auto' >>~/.config/nix/nix.conf

# install home manager
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install

# pull repo into ~/.config/nixpkgs/
cd ~/.config/nixpkgs
git clone git@github.com:jpetrucciani/nix.git .

# enable home-manager
home-manager switch
```
