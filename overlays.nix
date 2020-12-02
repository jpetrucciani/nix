with builtins; [
  (self: super:
    (x: { hax = x; }) (with super;
      with lib;
      with builtins;
      lib // rec {
        inherit (stdenv) isLinux isDarwin;
        inherit (pkgs) fetchFromGitHub;
        mapAttrValues = f: mapAttrs (n: v: f v);
        fakePlatform = x:
          x.overrideAttrs (attrs: {
            meta = attrs.meta or { } // {
              platforms = stdenv.lib.platforms.all;
            };
          });
        prefixIf = b: x: y: if b then x + y else y;
        mapLines = f: s:
          concatMapStringsSep "\n" (l: if l != "" then f l else l)
          (splitString "\n" s);
        words = splitString " ";
        attrIf = check: name: if check then name else null;
        alias = name: x:
          writeShellScriptBin name
          ''exec ${if isDerivation x then exe x else x} "$@"'';
        excludeLines = f: text:
          concatStringsSep "\n" (filter (x: !f x) (splitString "\n" text));
        drvs = x:
          if isDerivation x || isList x then
            flatten x
          else
            flatten (mapAttrsToList (_: v: drvs v) x);

        drvsExcept = x: e:
          with { excludeNames = concatMap attrNames (attrValues e); };
          flatten (drvs (filterAttrsRecursive (n: _: !elem n excludeNames) x));
      }))
  (self: super:
    with super;
    mapAttrs (n: v: hax.fakePlatform v) { inherit gixy; })
]

