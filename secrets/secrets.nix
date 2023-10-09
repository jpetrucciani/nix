let
  inherit (constants) pubkeys;
  constants = import ../hosts/constants.nix;
in
{
  "vaultwarden.age".publicKeys = with pubkeys; [ pluto terra ];
  "miniflux.age".publicKeys = with pubkeys; [ pluto terra ];
}
