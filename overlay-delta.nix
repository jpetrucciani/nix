{ local
, overlays
, root
, upstream
}:
let
  inherit (builtins) attrNames hasAttr length map unsafeGetAttrPos;
  inherit (upstream.lib) count hasPrefix removePrefix;

  system = local.stdenv.hostPlatform.system;
  rootPrefix = "${toString root}/";
  overlayAttrs = (upstream.lib.composeManyExtensions overlays) local upstream;
  names = attrNames overlayAttrs;

  formatPosition = position:
    if position == null
    then null
    else
      let
        file =
          if hasPrefix rootPrefix position.file
          then removePrefix rootPrefix position.file
          else position.file;
      in
      "${file}:${toString position.line}:${toString position.column}";

  formatPackageSource = source:
    let
      default = source + "/default.nix";
      file = if builtins.pathExists default then default else source;
      path = toString file;
    in
    if hasPrefix rootPrefix path
    then removePrefix rootPrefix path
    else path;

  inspect = name:
    {
      custom = hasAttr name local.custom;
      declaration =
        if hasAttr name local.custom
        then formatPackageSource local.__j_package_sources.${name}
        else formatPosition (unsafeGetAttrPos name overlayAttrs);
      inherit name;
      status = if hasAttr name upstream then "overridden" else "added";
    };

  entries = map inspect names;
  countEntries = predicate: count predicate entries;
in
{
  schemaVersion = 1;
  inherit entries system;
  inherit (local) nixpkgsRev;
  summary = {
    added = countEntries (entry: entry.status == "added");
    custom = countEntries (entry: entry.custom);
    declarations = length entries;
    overridden = countEntries (entry: entry.status == "overridden");
  };
}
