{ hex, ... }:
let
  inherit (hex) toYAML;

  traefik = rec {
    url = version: "https://helm.traefik.io/traefik/traefik-${version}.tgz";
    chart =
      { name ? "traefik${if internal then "-internal" else ""}"
      , namespace ? "traefik"
      , values ? [ (if internal then ./traefik/internal.yaml else ./traefik/external.yaml) ]
      , sets ? [ ]
      , version ? "10.24.0"
      , sha256 ? "1fcb9qq5ivg1kjd340xy231bkws4z76azyd5akka0lmmm86pmqsi"
      , forceNamespace ? true
      , extraFlags ? [ "--create-namespace" ]
      , internal ? false
      , sortYaml ? false
      }: hex.k8s.helm.build {
        inherit name namespace values sets version sha256 extraFlags forceNamespace sortYaml;
        url = url version;
      };
    ingress_route = rec {
      constants = { };
      build = args: ''
        ---
        ${toYAML (setup args)}
      '';
      setup = { name, domain, port ? 80, namespace ? "default", service ? name, internal ? true, secretName ? "" }: {
        apiVersion = "traefik.containo.us/v1alpha1";
        kind = "IngressRoute";
        metadata = {
          annotations = {
            "kubernetes.io/ingress.class" = if internal then "traefik-internal" else "traefik";
          };
          inherit name;
        };
        spec = {
          entryPoints = [
            "websecure"
          ];
          routes = [
            {
              kind = "Rule";
              match = "Host(`${domain}`)";
              services = [
                {
                  inherit namespace port;
                  name = service;
                }
              ];
            }
          ];
          tls = {
            inherit secretName;
          };
        };
      };
    };
  };
in
traefik
