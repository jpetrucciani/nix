# This overlay allows us to fake the build platform to attempt to build packages on unsupported OSes.
final: prev:
builtins.mapAttrs (_: prev.hax.fakePlatform) {
  inherit (prev) gixy brave;
}
