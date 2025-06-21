let
  isNixFile = file: builtins.match ".*\\.nix" file != null;
  moduleFiles = builtins.filter
    (file: file != "default.nix" && isNixFile file)
    (builtins.attrNames (builtins.readDir ./.));
in
builtins.map (file: ./. + "/${file}") moduleFiles
