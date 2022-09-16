{ hex, pkgs, ... }:
let
  inherit (hex) _if toYAML ifNotEmptyList;

  traefik = rec {
    url = version: "https://helm.traefik.io/traefik/traefik-${version}.tgz";
    chart =
      { name ? "traefik${if internal then "-internal" else ""}"
      , namespace ? "traefik"
      , sets ? [ ]
      , version ? "10.24.3"
      , sha256 ? "1dcby7c4bbjxv42c83n5g45na5hr9dmy0xgy0x2vb5b2rgbcmx70"
      , forceNamespace ? true
      , extraFlags ? [ "--create-namespace" ]
      , internal ? false
      , sortYaml ? false
        # other options
      , replicas ? 3
      , exposeTraefik ? false
      , portTraefik ? 9000
      , exposeHttp ? true
      , portHttp ? 8000
      , exposeHttps ? true
      , portHttps ? 8443
      }:
      let
        proto = {
          tcp = "TCP";
        };
        internalAnnotations =
          if internal then {
            service = {
              annotations = {
                "cloud.google.com/load-balancer-type" = "Internal";
                "service.beta.kubernetes.io/aws-load-balancer-internal" = "true";
              };
            };
          } else { };
        values = {
          additionalArguments = [
            "--log.level=DEBUG"
            "--ping"
            "--metrics.prometheus"
            "--serversTransport.insecureSkipVerify=true"
            "--entrypoints.web.forwardedHeaders.insecure"
          ] ++ (if exposeHttps then [
            "--entrypoints.websecure.http.tls"
            "--entrypoints.web.http.redirections.entryPoint.to=websecure"
            "--entrypoints.web.http.redirections.entryPoint.scheme=https"
            "--entrypoints.web.http.redirections.entrypoint.permanent=true"
            "--entrypoints.web.http.redirections.entryPoint.to=:443"
          ] else [ ]);
          deployment = {
            inherit replicas;
          };
          globalArguments = [ ];
          ports = {
            traefik = {
              expose = exposeTraefik;
              exposedPort = portTraefik;
              protocol = proto.tcp;
            };
            web = {
              expose = exposeHttp;
              exposedPort = portHttp;
              port = 8000;
              protocol = proto.tcp;
              # redirectTo = "websecure";
            };
            websecure = {
              expose = exposeHttps;
              exposedPort = portHttps;
              port = 8443;
              protocol = proto.tcp;
            };
          };
          providers = {
            kubernetesCRD = {
              allowCrossNamespace = true;
              ingressClass = name;
            };
          };
          tlsOptions = {
            default = {
              minVersion = "VersionTLS12";
              sniStrict = true;
            };
            mintls13 = {
              minVersion = "VersionTLS13";
            };
          };
        } // internalAnnotations;
        values_file = pkgs.writeTextFile {
          name = "traefik-values.yaml";
          text = toYAML values;
        };
      in
      hex.k8s.helm.build {
        inherit name namespace sets version sha256 extraFlags forceNamespace sortYaml;
        url = url version;
        values = [ values_file ];
      };
    ingress_route = rec {
      constants = { };
      build = args: ''
        ---
        ${toYAML (setup args)}
      '';
      setup = { name, domain, port ? 80, namespace ? "default", service ? name, internal ? true, secretName ? "", labels ? [ ] }:
        let
          secure = (builtins.stringLength secretName) > 0;
          entrypoint = if secure then "websecure" else "web";
          tlsOptions =
            if secure then {
              tls = {
                inherit secretName;
              };
            } else { };
        in
        {
          apiVersion = "traefik.containo.us/v1alpha1";
          kind = "IngressRoute";
          metadata = {
            inherit name;
            annotations = {
              "kubernetes.io/ingress.class" = if internal then "traefik-internal" else "traefik";
            };
            ${ifNotEmptyList labels "labels"} = labels;
          };
          spec = {
            entryPoints = [
              entrypoint
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
          } // tlsOptions;
        };
    };
  };
in
traefik
