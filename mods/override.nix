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
  # nixos-option = prev.nixos-option.override { nix = prev.nixVersions.nix_2_15; };
  # qdrant = prev.qdrant.overrideAttrs (old: { prePatch = ""; });

  github-runner = prev.github-runner.override {
    nodejs_16 = prev.nodejs_16.overrideAttrs (old: {
      meta = removeAttrs old.meta [ "knownVulnerabilities" ];
    });
    nodeRuntimes = [ "node16" "node20" ];
  };
}
