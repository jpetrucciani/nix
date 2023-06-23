final: prev:
let
  inherit (prev.stdenv) isDarwin isLinux;
in
{
  docker = prev.docker.override { withLvm = isLinux; };

  # fix for getting yank working on darwin
  yank = prev.yank.overrideAttrs (attrs: {
    makeFlags = if isDarwin then [ "YANKCMD=/usr/bin/pbcopy" ] else attrs.makeFlags;
  });

  # fix for python3Packages.ray
  py-spy = prev.py-spy.overrideAttrs (old: {
    doCheck = false;
  });
}
