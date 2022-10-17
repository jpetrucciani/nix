final: prev:
with prev;
rec {
  _zaddy =
    let
      builtins = {
        caddy-cgi = { name = "github.com/aksdb/caddy-cgi"; version = "7cf2523251ffeef310868d8ed03e17a929236f2e"; };
        caddy-exec = { name = "github.com/abiosoft/caddy-exec"; version = "06d4f7218eb886ab9664e63c3f56010992e93fb9"; };
        caddy-security = { name = "github.com/greenpau/caddy-security"; version = "v1.1.15"; };
        caddy-webhook = { name = "github.com/WingLim/caddy-webhook"; version = "v1.0.8"; };
        certmagic-storage-dynamodb = { name = "github.com/silinternational/certmagic-storage-dynamodb"; version = "3.0.0"; };

        # dns
        alidns = { name = "github.com/caddy-dns/alidns"; version = "1.0.21"; };
        azure = { name = "github.com/caddy-dns/azure"; version = "v0.2.0"; };
        cloudflare = { name = "github.com/caddy-dns/cloudflare"; version = "815abbf88b27182428c342b2916a37b7134d266b"; };
        digitalocean = { name = "github.com/caddy-dns/digitalocean"; version = "9c71e343246b954976c9294a7062823605de9b9f"; };
        dnspod = { name = "github.com/caddy-dns/dnspod"; version = "v0.0.4"; };
        duckdns = { name = "github.com/caddy-dns/duckdns"; version = "v0.3.1"; };
        gandi = { name = "github.com/caddy-dns/gandi"; version = "v1.0.2"; };
        hetzner = { name = "github.com/caddy-dns/hetzner"; version = "v0.0.1"; };
        route53 = { name = "github.com/caddy-dns/route53"; version = "v1.2.1"; };
        vultr = { name = "github.com/caddy-dns/vultr"; version = "733392841379526fd314012909963c3c6406687a"; };

        # s3 stuff
        s3-proxy = { name = "github.com/lindenlab/caddy-s3-proxy"; version = "v0.5.6"; };
        s3-browser = { name = "github.com/jpetrucciani/caddy-s3browser"; version = "b553c40251fd727217b3e49eb5c69d18c4460e08"; };

        # utils
        caddy-git = { name = "github.com/greenpau/caddy-git"; version = "v1.0.7"; };
        caddy-json-parse = { name = "github.com/abiosoft/caddy-json-parse"; version = "c57039f26567f4b4120e35b4dc1a9bbd20a4f37f"; };
        caddy-ratelimit = { name = "github.com/mholt/caddy-ratelimit"; version = "9c011f665e5ddff32fe00cab338ace7f360114ff"; };
        caddy-trace = { name = "github.com/greenpau/caddy-trace"; version = "v1.1.10"; };
        # caddy-troll = { name = "github.com/jpetrucciani/caddy-troll"; version = "bd687c6c60e24f9cf5c8309cbdd48e56629ba71c"; };
        geolocation = { name = "github.com/jpetrucciani/caddy-maxmind-geolocation"; version = "65f8416054495107983d1c5fe128658f35b5e60a"; };
        replace_response = { name = "github.com/caddyserver/replace-response"; version = "d32dc3ffff0c07a3c935ef33092803f90c55ba19"; };
        user_agent_parse = { name = "github.com/neodyme-labs/user_agent_parse"; version = "450380e8b6d048d71937014932ba6d4d56dd611d"; };
      };
    in
    { plugins
    , vendorSha256
    }:
    let
      allPlugins = final.lib.flatten (plugins builtins);
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
      zaddy = prev.caddy.override {
        buildGoModule = args: buildGo119Module (args // {
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
            sed -i -E '/Group=caddy/aEnvironmentFile=/etc/default/caddy\nTimeoutSec=180' $out/lib/systemd/system/caddy.service
          '';
          postPatch = caddyPatchMain;
          preBuild = "cp vendor/go.mod vendor/go.sum .";
        });
      };
    in
    zaddy;
  caddy = prev.caddy.overrideAttrs (_: { passthru.withPackages = _zaddy; });

  # my preferred caddy install
  zaddy = _zaddy {
    plugins = p: with p; [
      caddy-security
      s3-proxy
      geolocation
      # caddy-troll
    ];
    vendorSha256 = "sha256-P7PxSjA4XFm6x9tMGybYs7FX5GkFAzou6qvkYIiz8kg=";
  };

  # caddy with s3-browser plugin
  zaddy-browser = _zaddy {
    plugins = p: with p; [
      caddy-security
      s3-proxy
      s3-browser
    ];
    vendorSha256 = "sha256-Zh6tF/N1HR4sceKUTRIiC13s+8TrEgkDLF0lqKyx+IA=";
  };
}
