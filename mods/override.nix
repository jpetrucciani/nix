# This overlay provides some overrides/fixes for various packages
final: prev:
let
  inherit (final.stdenv) isDarwin;
  zitadel_pr = import
    (builtins.fetchTarball {
      url = "https://github.com/jpetrucciani/nixpkgs/archive/535a908c603f65a6ceed636221a3148465cfb716.tar.gz";
      sha256 = "13jgyc0b9l6j80dzsk1bwia4vsyh7q7kwxjl5fv402gypycij275";
    })
    { system = "x86_64-linux"; };
in
{
  inherit (zitadel_pr) zitadel;
  # fix for getting yank working on darwin
  yank = prev.yank.overrideAttrs (attrs: {
    makeFlags = if isDarwin then [ "YANKCMD=/usr/bin/pbcopy" ] else attrs.makeFlags;
  });

  # fix for python3Packages.ray
  py-spy = prev.py-spy.overrideAttrs (old: {
    doCheck = false;
  });
}
