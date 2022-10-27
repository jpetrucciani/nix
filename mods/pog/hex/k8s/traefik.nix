{ hex, pkgs, ... }:
let
  inherit (hex) _if toYAML ifNotEmptyList;

  traefik = rec {
    defaults = {
      name = "traefik";
      namespace = "traefik";
      version = "18.1.0";
      sha256 = "0ablg2nhnwfvjhys01syyzrihfakvb640gq1gp386pcadhjsr5iw";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      v10-24-3 = _v "10.24.3" "1dcby7c4bbjxv42c83n5g45na5hr9dmy0xgy0x2vb5b2rgbcmx70";
      v10-33-0 = _v "10.33.0" "02692bgy5g1p7v9fdclb2fmxxv364kv7xbw2b1z5c2r1wj271g6k";
      v11-1-1 = _v "11.1.1" "0rj97xam3rszgvfvviyv4933k5g61h5s782k2ir9arr0fgwvy50b";
      v12-0-2 = _v "12.0.2" "0kkknd4lad1r8vclwxfgl3rqr8yjmwp2rsyf9znmmr7ms91ajh8a";
      v12-0-7 = _v "12.0.7" "1hy7ikx2zcwyh8904h792f63mz689bxnwqps4wxsbmw626p3wz8p";
      v13-0-1 = _v "13.0.1" "13fdl2jgfz3afy15z69c4gqqw9yxs31mbn890kwsji0nysqm2x4d";
      v14-0-1 = _v "14.0.1" "1san9gi139v53q9fwcihbd9ddnq612zqc3gyhx4vr27y95jh6h2z";
      v15-0-0 = _v "15.0.0" "0xih856ikw1s7lqs1cxhkmw7xcmp9jijyh3crj0jk8ffcxkj0wbf";
      v18-0-0 = _v "18.0.0" "0ay3rg7knc5c7mr5n51yhq3vavm983ggnrjql3slhzmp9rxl3lmp";
      v18-1-0 = _v defaults.version defaults.sha256;
      latest = v18-1-0;
    };
    index_url = "https://helm.traefik.io/traefik/index.yaml";
    chart_url = version: "https://helm.traefik.io/traefik/traefik-${version}.tgz";
    chart =
      { name ? "traefik${if internal then "-internal" else ""}"
      , namespace ? defaults.namespace
      , sets ? [ ]
      , version ? defaults.version
      , sha256 ? defaults.sha256
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
              } // hex.annotations;
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
        url = chart_url version;
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
            } // hex.annotations;
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
