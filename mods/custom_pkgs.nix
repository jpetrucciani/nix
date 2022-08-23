final: prev:
with builtins;
let
  extra-packages =
    with prev;
    (
      fn:
      lib.optionalAttrs (pathExists ../pkgs)
        (listToAttrs (lib.mapAttrsToList fn (readDir ../pkgs)))
    ) (
      n: _: rec {
        name = lib.removeSuffix ".nix" n;
        value = pkgs.callPackage (../pkgs + ("/" + n))
          {
            nodejs = pkgs.nodejs-14_x;
          };
      }
    );
in
{ inherit extra-packages; } // extra-packages
