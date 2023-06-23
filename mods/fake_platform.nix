final: prev:
builtins.mapAttrs (_: prev.hax.fakePlatform) {
  inherit (prev) gixy brave;
}
