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

  _std = (import ../flake-compat.nix).inputs.nix-std.lib;

  sssd = prev.sssd.override { python3 = final.python311; };

  # lock down terraform 1.5.5 as the final open source version
  terraform_1-5-5_src = import
    (builtins.fetchGit {
      name = "terraform-1.5.5";
      url = "https://github.com/NixOS/nixpkgs/";
      ref = "refs/heads/nixpkgs-unstable";
      rev = "976fa3369d722e76f37c77493d99829540d43845";
    })
    { inherit (final) system; };
}
