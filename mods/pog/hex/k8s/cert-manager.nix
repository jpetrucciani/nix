# [cert-manager](https://github.com/cert-manager/cert-manager/) adds certificates and certificate issuers as resource types in Kubernetes clusters, and simplifies the process of obtaining, renewing and using those certificates.
{ hex, ... }:
let
  inherit (hex) toYAMLDoc;

  cert-manager = rec {
    defaults = {
      name = "cert-manager";
      namespace = "cert-manager";
      version = "1.9.1";
      sha256 = "0jr4ifqv25fagjgjp8m5gk5cb00h7ppqza3nzr8gwd4dmx62kss7";
    };
    version = rec {
      _v = v: s: chart.build { version = v; sha256 = s; };
      v1-7-1 = _v "1.7.1" "00pp4cplf018a89awj2wmy8q86926qq5y1zpmgkc1djvdpmxrj5d";
      v1-9-1 = _v defaults.version defaults.sha256;
      latest = v1-9-1;
    };
    chart_url = version: "https://github.com/cert-manager/cert-manager/releases/download/v${version}/cert-manager.yaml";
    chart = rec {
      build = { version ? defaults.version, sha256 ? defaults.sha256 }: ''
        ---
        ${setup {inherit version sha256;}}
      '';
      setup = { version, sha256 }: builtins.readFile (builtins.fetchurl {
        inherit sha256;
        url = chart_url version;
      });
    };
    certificate = rec {
      build = args: toYAMLDoc (cert args);
      cert = { name, namespace ? "default", issuer ? "letsencrypt-prod", dns_names ? [ ] }: {
        apiVersion = "cert-manager.io/v1";
        kind = "Certificate";
        metadata = {
          inherit name namespace;
          annotations = { } // hex.annotations;
        };
        spec = {
          secretName = name;
          issuerRef = {
            name = issuer;
            kind = "ClusterIssuer";
          };
          dnsNames = dns_names;
        };
      };
    };
    cluster_issuer =
      let
        acme_servers = {
          prod = "https://acme-v02.api.letsencrypt.org/directory";
          staging = "https://acme-staging-v02.api.letsencrypt.org/directory";
        };
      in
      rec {
        build =
          { email
          , name ? "letsencrypt-prod"
          , ingress_class ? "traefik"
          , acme_server ? if staging then acme_servers.staging else acme_servers.prod
          , staging ? false
          , solvers ? [ ]
          }: toYAMLDoc (issuer { inherit name ingress_class acme_server email solvers; });

        issuer = { name, ingress_class, acme_server, email, solvers }:
          let
            all_solvers = solvers ++ [
              {
                http01 = {
                  ingress = {
                    class = ingress_class;
                  };
                };
              }
            ];
          in
          {
            apiVersion = "cert-manager.io/v1";
            kind = "ClusterIssuer";
            metadata = {
              inherit name;
              annotations = { } // hex.annotations;
            };
            spec = {
              acme = {
                inherit email;
                solvers = all_solvers;
                server = acme_server;
                privateKeySecretRef = {
                  name = "${name}-key";
                };
              };
            };
          };
      };
    # dns solvers
    solvers = {
      route53 = { zone, region, accessKeyID, dns_secret_ref, dns_secret_key }: {
        dns01 = {
          route53 = {
            inherit region accessKeyID;
            secretAccessKeySecretRef = {
              name = dns_secret_ref;
              key = dns_secret_key;
            };
          };
        };
        selector = { dnsZones = [ zone ]; };
      };
      gcp = { gcp_project, dns_secret_ref, dns_secret_key }: {
        dns01 = {
          cloudDNS = {
            project = gcp_project;
            serviceAccountSecretRef = {
              name = dns_secret_ref;
              key = dns_secret_key;
            };
          };
        };
      };
    };
  };
in
cert-manager
