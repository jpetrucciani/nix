let
  inherit (constants) pubkeys;
  constants = import ../hosts/constants.nix;
  default = with pubkeys; [ milkyway pluto terra ];
in
{
  "vaultwarden.age".publicKeys = default;
  "miniflux.age".publicKeys = default;
}
