final: prev:
let
  inherit (final.writers) writeBashBin;
in
{
  scripts = {
    foo = writeBashBin "foo" ''
      echo bar
    '';
    ci_cache = writeBashBin "ci_cache" ''
      mkdir -p ~/.aws
      echo "$S3_CREDS" | base64 -d >~/.aws/credentials
      echo "$PRIVKEY" | base64 -d >/tmp/cache.priv.pem
      nix run .#nixcache ./result*
      rm /tmp/cache.priv.pem ~/.aws/credentials
    '';
  };
}
