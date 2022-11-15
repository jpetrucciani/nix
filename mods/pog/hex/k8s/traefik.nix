{ hex, pkgs, ... }:
let
  inherit (hex) _if toYAML ifNotEmptyList;

  traefik = rec {
    defaults = {
      name = "traefik";
      namespace = "traefik";
      version = "20.2.0";
      sha256 = "01q64bx4q54n15qivddxifl3lm7iy2148l0qc61zhhh1wp2d07ha";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      latest = v20-2-0;
      v20-2-0 = _v defaults.version defaults.sha256;
      v20-1-1 = _v "20.1.1" "1nsali7nbyrjx99pqqcs7y0y9fhcg4xla3hpy11wn1axdlr7mr3w";
      v20-1-0 = _v "20.1.0" "1q79vf4z24pya9v33syhv7f50jr8l2vhdmxqvrb5w9v92drpi57z";
      v20-0-0 = _v "20.0.0" "09pj1xg7ldprlbcp3jmbiw1f395llf0vbaa9xxffiwh56f5nc8mk";
      v19-0-4 = _v "19.0.4" "1j0fgr2jmi8p2zxf7k8764lidmw96vqcy5y821hlr66a8l1cp1iy";
      v19-0-3 = _v "19.0.3" "1dshzin4gx8lbm49lf7w75jv5bvya2dzcdvmlynz6q3w8i601lsl";
      v19-0-2 = _v "19.0.2" "1xifm3bqcg6z91k4f5x2aj854lqjmn50c68q993wmmb9glf1519m";
      v19-0-1 = _v "19.0.1" "09ms5r7m49pkb2wdnzy452c0va4crr0xp61p0i9gkc009x58r15p";
      v19-0-0 = _v "19.0.0" "0pmgw6kfmm1kh3ifn80pkj3pxpzdbgdz4mc214vqc2lnlxrdxzwl";
      v12-0-7 = _v "12.0.7" "1hy7ikx2zcwyh8904h792f63mz689bxnwqps4wxsbmw626p3wz8p";
    };
    index_url = "https://traefik.github.io/charts/index.yaml";
    chart_url = version: "https://traefik.github.io/charts/traefik/traefik-${version}.tgz";
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
      , logLevel ? "DEBUG"
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
            "--log.level=${logLevel}"
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
