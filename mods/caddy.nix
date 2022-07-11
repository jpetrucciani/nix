final: prev:
with prev;
rec {
  _xcaddy =
    let
      builtins = {
        caddy-security = { name = "github.com/greenpau/caddy-security"; version = "v1.1.14"; };
        s3-proxy = { name = "github.com/lindenlab/caddy-s3-proxy"; version = "v0.5.6"; };
        s3-browser = { name = "github.com/techknowlogick/caddy-s3browser"; version = "81830de0e8d78d414488f1e621082ee732e7c3de"; };
        geolocation = { name = "github.com/porech/caddy-maxmind-geolocation"; version = "89d86498ab7d55c9212c0c6b4d1ac9026929147b"; };
      };
    in
    { plugins
    , vendorSha256
    }:
    let
      allPlugins = plugins builtins;
      caddyPatchMain = final.lib.strings.concatMapStringsSep "\n"
        ({ name, version }: ''
          sed -i '/plug in Caddy modules here/a\\t_ "${name}"' cmd/caddy/main.go
        '')
        allPlugins;
      caddyPatchGoGet = final.lib.strings.concatMapStringsSep "\n"
        ({ name, version }: ''
          go get ${name}@${version}
        '')
        allPlugins;
      xcaddy = prev.caddy.override {
        buildGoModule = args: buildGoModule (args // {
          inherit vendorSha256;
          overrideModAttrs = _: {
            preBuild = ''
              ${caddyPatchMain}
              ${caddyPatchGoGet}
            '';
            postInstall = "cp go.mod go.sum $out/";
          };
          postInstall = ''
            ${args.postInstall}
            sed -i -E '/Group=caddy/aEnvironmentFile=/etc/default/caddy' $out/lib/systemd/system/caddy.service
          '';
          postPatch = caddyPatchMain;
          preBuild = "cp vendor/go.mod vendor/go.sum .";
        });
      };
    in
    xcaddy;
  caddy = prev.caddy.overrideAttrs (_: { passthru.withPackages = _xcaddy; });

  # my preferred caddy install
  xcaddy = _xcaddy {
    plugins = p: with p; [
      caddy-security
      s3-proxy
      geolocation
    ];
    vendorSha256 = "sha256-LRK8v2O36ZVnfADCZ+7tQhAz8wL0vc3UfXsEmfmuyRg=";
  };

  # caddy with s3-browser plugin
  xcaddy-browser = _xcaddy {
    plugins = p: with p; [
      caddy-security
      s3-proxy
      s3-browser
    ];
    vendorSha256 = "sha256-aKnOah0mu5rM2WfAx9NSg8i2M3OzYXjZARWJs+ETxeI=";
  };

}
