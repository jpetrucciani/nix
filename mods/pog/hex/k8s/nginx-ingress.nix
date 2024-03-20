# [nginx-ingress controller](https://github.com/kubernetes/ingress-nginx)
_:
let
  inherit (builtins) fetchurl readFile;
  nginx = rec {
    defaults = {
      name = "nginx-ingress";
      version = "1.10.0";
      sha256 = "1xz4zdk9pmgjxmbaj6iv2knmc65lpvv2wsnp2rhdsg72hr4ykk6k";
    };
    version = rec {
      _v = v: s: chart.build { version = v; sha256 = s; };
      latest = v1-10-0;
      v1-10-0 = _v defaults.version defaults.sha256;
      v1-4-0 = _v "1.4.0" "1012gghaq81h6ja2pnf4gwjrh4mv4vjj7zsv2l48p4apa5l3r5fw";
      v1-3-0 = _v "1.3.0" "0r35jpa6icykbbxbls9dbhwzrswsi85qssgh6xsv6sgj4s5z8gxs";
      v1-2-1 = _v "1.2.1" "1f0xpylnnn42vx6q5arm67f6jgfalwc0rng3f2dxc0mkzk286f52";
      v1-2-0 = _v "1.2.0" "13ww8pz1fwqf08rkvpn05h73mpg1s42dndnpspid7hf63s9zshcg";
      v1-1-3 = _v "1.1.3" "0454qi31pvlg7gz9b56nirbz56avmahl41gb4j0j6mxvakfpjx2k";
      v1-1-2 = _v "1.1.2" "1664q63aa4dfl6icm5w8frp4h2w4vq949x5f5r6r9986xq99fcl4";
      v1-1-1 = _v "1.1.1" "0z5i5pbbbsh4brjh3z8adppndpwzhhbvdcfc807rhqkmaqpkwwvw";
      v1-1-0 = _v "1.1.0" "1s28pqxp7ys9dn1ryl2hcmdgq9pi412kx0wpbljrfm58ixhb9sa7";
      v1-0-5 = _v "1.0.5" "1rwd29hsr7ggkb2y6qab27haa3lmavnbfvag2r8d1z51nyvdma47";
      v1-0-4 = _v "1.0.4" "1s28pqxp7ys9dn1ryl2hcmdgq9pi412kx0wpbljrfm58ixhb9sa7";
      v1-0-2 = _v "1.0.2" "1h643pl5l6f2kalplqlhl2ka63ij4zkkk19ica8n1qg2cv2glsb2";
    };
    spec_url = version: "https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v${version}/deploy/static/provider/cloud/deploy.yaml";
    chart = rec {
      build = { version ? defaults.version, sha256 ? defaults.sha256 }: ''
        ---
        ${setup {inherit version sha256;}}
      '';
      setup = { version, sha256 }: readFile (fetchurl {
        inherit sha256;
        url = spec_url version;
      });
    };
  };
in
nginx
