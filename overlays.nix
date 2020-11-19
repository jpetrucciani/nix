with builtins;
[
  (self: super: with super; {
    fakePlatform = x: x.overrideAttrs (attrs:
      { meta = attrs.meta or { } // { platforms = stdenv.lib.platforms.all; }; }
    );
  })
  (self: super: with super; mapAttrs (n: v: fakePlatform v) { inherit gixy; })
]

