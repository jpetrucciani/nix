let
  modulesIn = directory:
    let
      entries = builtins.readDir directory;
      moduleFor = name:
        let
          path = directory + "/${name}";
          nixFile = builtins.match "(.*)\\.nix" name;
          default = path + "/default.nix";
        in
        if entries.${name} == "regular" && nixFile != null
        then [{ name = builtins.head nixFile; inherit path; }]
        else if entries.${name} == "directory" && builtins.pathExists default
        then [{ inherit name; path = default; }]
        else [ ];
      modules = builtins.concatLists (builtins.map moduleFor (builtins.attrNames entries));
      names = builtins.map (module: module.name) modules;
      duplicateNames = builtins.filter
        (name: builtins.length (builtins.filter (other: other == name) names) > 1)
        names;
    in
    if duplicateNames == [ ]
    then modules
    else throw "Duplicate module names in ${toString directory}: ${builtins.toJSON duplicateNames}";
  importOverlays = directory: builtins.map (module: import module.path) (modulesIn directory);
  packageOverlays = importOverlays ./mods/pkgs;
  pogOverlays =
    builtins.filter builtins.isFunction (
      importOverlays ./mods/pog
    );
  patchOverlays = builtins.map
    (module:
      final: prev:
        let
          previous = prev.${module.name} or (throw "Cannot patch missing package ${module.name}");
          scope = final // {
            inherit final;
            prev = previous;
          };
          _overlay = {
            inherit final;
            inherit (module) name path;
            prev = previous;
          };
          patch = import module.path;
          patchArgs = builtins.intersectAttrs
            (builtins.functionArgs patch)
            (scope // { inherit _overlay scope; });
        in
        {
          ${module.name} = patch patchArgs;
        })
    (modulesIn ./mods/patches);
in
[
  (import ./mods/hax.nix)
  (import ./mods/_pkgs.nix)
  (import ./mods/override.nix)
  (import ./mods/bashbible.nix)
  (import ./mods/fake_platform.nix)
  (import ./mods/hashers.nix)
  (import ./mods/lang.nix)
  (import ./mods/hms.nix)

  # python sub-overlays
  (import ./mods/python/default.nix)

  # ocaml sub-overlays
  (import ./mods/ocaml/default.nix)

  # sub-overlays
] ++ packageOverlays ++ patchOverlays ++ pogOverlays ++ [
  # after all
  (import ./scripts.nix)
  (import ./mods/containers.nix)
  (import ./mods/java.nix)
  (import ./mods/js.nix)
  (import ./mods/snowball.nix)
  (import ./mods/py_madness.nix)
  (import ./mods/final.nix)
]
