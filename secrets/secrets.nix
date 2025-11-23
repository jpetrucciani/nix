let
  inherit (constants) pubkeys;
  constants = import ../hosts/constants.nix;
  default = with pubkeys; [ milkyway pluto terra voyager ];
in
{
  "authelia.age".publicKeys = default;
  "miniflux.age".publicKeys = default;
  "ntfy.age".publicKeys = default;
  "vaultwarden.age".publicKeys = default;
  "zitadel.age".publicKeys = default;
}
