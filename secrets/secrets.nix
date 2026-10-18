let
  inherit (constants) pubkeys;
  constants = import ../hosts/constants.nix;
  default = with pubkeys; [ pluto terra voyager ];
  bella = default ++ [ pubkeys.titan ];
  goblin = default ++ [ pubkeys.cy1-nix-01 ];
in
{
  "authelia.age".publicKeys = default;
  "miniflux.age".publicKeys = default;
  "ntfy.age".publicKeys = default;
  "vaultwarden.age".publicKeys = default;
  "bella/token.age".publicKeys = bella;
  "bella/ssh.age".publicKeys = bella;
  "bella/github.com.age".publicKeys = bella;
  "bella/git.cobi.dev.age".publicKeys = bella;
  "goblin/token.age".publicKeys = goblin;
  "goblin/ssh.age".publicKeys = goblin;
  "goblin/gitlab.com.age".publicKeys = goblin;
}
