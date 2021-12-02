prev: next:
with next;
builtins.mapAttrs (n: v: hax.fakePlatform v) {
  inherit gixy;
  inherit brave;
}
  
