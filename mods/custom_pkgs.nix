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
        value = pkgs.callPackage (../pkgs + ("/" + n)) { };
      }
    );
in
{ inherit extra-packages; } // extra-packages
