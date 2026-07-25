{ _overlay, scope }: with scope;
prev.overrideAttrs (old: {
  installPhase = old.installPhase + ''
    chmod -R u+w "$out"
    patch -p1 -d "$out" < ${./hash-based-profile.patch}
  '';
})
