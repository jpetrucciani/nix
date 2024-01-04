let
  inherit (constants) pubkeys;
  constants = import ../hosts/constants.nix;
  default = with pubkeys; [ milkyway pluto terra ];
in
{
  "authelia.age".publicKeys = default;
  "miniflux.age".publicKeys = default;
  "vaultwarden.age".publicKeys = default;
  "zitadel.age".publicKeys = default;
}
