final: prev:
let
  inherit (builtins) listToAttrs pathExists readDir;
  inherit (prev.lib) hasSuffix mapAttrsToList optionalAttrs removeSuffix;
  inherit (prev.lib.attrsets) filterAttrs;
  inherit (prev.pkgs) callPackage nodejs-16_x;
  custom =
    (
      fn:
      optionalAttrs (pathExists ../pkgs)
        (listToAttrs (mapAttrsToList fn (filterAttrs (k: v: (v == "directory") || (hasSuffix ".nix" k)) (readDir ../pkgs))))
    ) (
      n: _: {
        name = removeSuffix ".nix" n;
        value = callPackage (../pkgs + ("/" + n))
          {
            inherit (prev) pkgs;
            nodejs = nodejs-16_x;
          };
      }
    );
in
{
  inherit custom;
} // custom
