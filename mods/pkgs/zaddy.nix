# This overlay provides a [caddy web server](https://caddyserver.com/v2) builder function called `_zaddy` and a set of default plugins that you can use to build any flavor of caddy that you'd like!
final: prev:
with prev;
rec {
  _zaddy =
    let
      builtins = {
        caddy-cgi = { name = "github.com/aksdb/caddy-cgi"; version = "7cf2523251ffeef310868d8ed03e17a929236f2e"; };
        caddy-exec = { name = "github.com/abiosoft/caddy-exec"; version = "06d4f7218eb886ab9664e63c3f56010992e93fb9"; };
        caddy-security = { name = "github.com/greenpau/caddy-security"; version = "v1.1.29"; };
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
        googleclouddns = { name = "github.com/caddy-dns/googleclouddns"; version = "v1.0.4"; };
        porkbun = { name = "github.com/caddy-dns/porkbun"; version = "v0.2.1"; };
        hetzner = { name = "github.com/caddy-dns/hetzner"; version = "v0.0.1"; };
        route53 = { name = "github.com/caddy-dns/route53"; version = "v1.2.1"; };
        tencentcloud = { name = "github.com/caddy-dns/tencentcloud"; version = "v0.1.0"; };
        vultr = { name = "github.com/caddy-dns/vultr"; version = "733392841379526fd314012909963c3c6406687a"; };

        # s3 stuff
        s3-proxy = { name = "github.com/jpetrucciani/caddy-s3-proxy"; version = "f818d1a7bb35c74f37d4a809236024e9f464162d"; };
        # s3-proxy = { name = "github.com/lindenlab/caddy-s3-proxy"; version = "v0.5.6"; };
        s3-browser = { name = "github.com/jpetrucciani/caddy-s3browser"; version = "b553c40251fd727217b3e49eb5c69d18c4460e08"; };

        # gcs stuff
        gcs-proxy = { name = "github.com/jpetrucciani/caddy-gcs-proxy"; version = "98628394327ca61587d02497353dd3a1dc2ac726"; };

        # utils
        ## jacobi's plugins
        caddy-hax = { name = "github.com/jpetrucciani/caddy-hax"; version = "v0.0.2"; };
        caddy-troll = { name = "github.com/jpetrucciani/caddy-troll"; version = "v0.0.1"; };
        ## other
        caddy-defender = { name = "github.com/JasonLovesDoggo/caddy-defender"; version = "e4a3e26e7dfd5e770fc9a196b3c78f1a2635f3cf"; };
        cache-handler = { name = "github.com/caddyserver/cache-handler"; version = "v0.11.0"; };
        caddy-bandwidth = { name = "github.com/mediafoundation/caddy-bandwidth"; version = "v1.0.10"; };
        caddy-git = { name = "github.com/greenpau/caddy-git"; version = "v1.0.9"; };
        caddy-json-parse = { name = "github.com/abiosoft/caddy-json-parse"; version = "c57039f26567f4b4120e35b4dc1a9bbd20a4f37f"; };
        caddy-l4 = { name = "github.com/mholt/caddy-l4"; version = "22554b119f249f9cac5626ada525cd257f2fb404"; };
        caddy-ratelimit = { name = "github.com/mholt/caddy-ratelimit"; version = "2dc0d586f0b87e983757c403bc0929ddeb84a537"; };
        caddy-trace = { name = "github.com/greenpau/caddy-trace"; version = "v1.1.13"; };
        forwardproxy = { name = "github.com/caddyserver/forwardproxy"; version = "1.0.1"; };
        geolocation = { name = "github.com/jpetrucciani/caddy-maxmind-geolocation"; version = "456a3bae9dbd0fe882eb806e8fb0d21bf5e11610"; };
        pkl-adapter = { name = "github.com/caddyserver/pkl-adapter"; version = "5b5eecd6f104d0ea95fb7031dbd0c0c79e7e1e5d"; };
        replace_response = { name = "github.com/caddyserver/replace-response"; version = "a85d4ddc11d635c093074205bd32f56d05fc7811"; };
        user_agent_parse = { name = "github.com/neodyme-labs/user_agent_parse"; version = "450380e8b6d048d71937014932ba6d4d56dd611d"; };
      };
    in
    { plugins
    , vendorHash
    }:
    let
      allPlugins = final.lib.flatten (plugins builtins);
      caddyPatchMain = final.lib.strings.concatMapStringsSep "\n"
        ({ name, ... }: ''
          sed -i '/plug in Caddy modules here/a\\t_ "${name}"' cmd/caddy/main.go
        '')
        allPlugins;
      caddyPatchGoGet = final.lib.strings.concatMapStringsSep "\n"
        ({ name, version }: ''
          go get ${name}@${version}
        '')
        allPlugins;
      zaddy =
        let
          version = "2.9.1";
          src = fetchFromGitHub {
            owner = "caddyserver";
            repo = "caddy";
            rev = "v${version}";
            hash = "sha256-XW1cBW7mk/aO/3IPQK29s4a6ArSKjo7/64koJuzp07I=";
          };
        in
        prev.caddy.override {
          buildGoModule = args: buildGo124Module (args // {
            inherit version src;
            inherit vendorHash;
            overrideModAttrs = _: {
              preBuild = ''
                ${caddyPatchMain}
                ${caddyPatchGoGet}
              '';
              postInstall = "cp go.mod go.sum $out/";
            };
            postInstall = ''
              ${args.postInstall}
              sed -i -E '/Group=caddy/aEnvironmentFile=-/etc/default/caddy\nTimeoutSec=180' $out/lib/systemd/system/caddy.service
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
      gcs-proxy
      geolocation
      caddy-hax
      caddy-troll
      # dns providers
      googleclouddns
      route53
    ];
    vendorHash = "sha256-EUJqeo6sWT5N334MQ73iNVcOMVEalu31vescu9ckm5g=";
  };

  # caddy with s3-browser plugin
  # zaddy-browser = _zaddy {
  #   plugins = p: with p; [
  #     caddy-security
  #     s3-proxy
  #     s3-browser
  #   ];
  #   vendorHash = "";
  # };
}
