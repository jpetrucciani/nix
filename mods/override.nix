final: prev:
let
  inherit (prev.stdenv) isDarwin;
in
{
  # fix for getting yank working on darwin
  yank = prev.yank.overrideAttrs (attrs: {
    makeFlags = if isDarwin then [ "YANKCMD=/usr/bin/pbcopy" ] else attrs.makeFlags;
  });

  # fix for python3Packages.ray
  py-spy = prev.py-spy.overrideAttrs (old: {
    doCheck = false;
  });
  # nixos-option = prev.nixos-option.override { nix = prev.nixVersions.nix_2_15; };
  # qdrant = prev.qdrant.overrideAttrs (old: { prePatch = ""; });
}
