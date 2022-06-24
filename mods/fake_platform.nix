final: prev:
with prev;
builtins.mapAttrs (_: hax.fakePlatform) {
  inherit gixy;
  inherit brave;
}
