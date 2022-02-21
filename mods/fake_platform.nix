prev: next:
with next;
builtins.mapAttrs (_: hax.fakePlatform) {
  inherit gixy;
  inherit brave;
}
