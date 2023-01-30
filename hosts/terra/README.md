# terra

## bootstrap

```bash
# load nixos iso
# nixos-up
sudo nix-shell https://nix.cobi.dev/os-up

# generate ssh key, add to github
ssh-keygen -o -a 100 -t ed25519 -C "jacobi@terra"

# clone repo
nix-shell -p git
git clone git@github.com:jpetrucciani/nix.git ~/cfg
cd ~/cfg

# initial switch
export HOSTNAME='terra'
nix build --extra-experimental-features -f . hms
./result/bin/hms
```
