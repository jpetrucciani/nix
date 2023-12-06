let
  inherit (constants) pubkeys;
  constants = import ../hosts/constants.nix;
  default = with pubkeys; [ milkyway terra ];
in
{
  "vaultwarden.age".publicKeys = default;
  "miniflux.age".publicKeys = default;
}
