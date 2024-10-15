# [Traefik](https://github.com/traefik/traefik-helm-chart) is a modern HTTP reverse proxy and load balancer made to deploy microservices with ease.
{ hex, pkgs, ... }:
let
  inherit (hex) toYAML toYAMLDoc ifNotEmptyList;

  traefik = rec {
    defaults = {
      name = "traefik";
      namespace = "traefik";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v32-1-1;
      v32-1-1 = _v "32.1.1" "1i9cyy6s6jbv8bhd5gncp6lnd78iqzvr0kmarxs52gf78v7rb0nb"; # 2024-10-11
      v32-0-0 = _v "32.0.0" "18agkj3pn5wy2qghfpaj6wvrq9sg55ignp2cqm820kdxjkvfag7n"; # 2024-09-27
      v31-1-1 = _v "31.1.1" "1jidj68wwa93jz9rwx682fxdh6fp4rmjg83m7xbjfqcv3sw1ma6q"; # 2024-09-20
      v31-0-0 = _v "31.0.0" "1xn9iyr527aiwm1nqa7q3gw2gi9p0mnbh9yf2x5jj10kkpvn667r"; # 2024-09-03
      v30-1-0 = _v "30.1.0" "1s5mrly25rs9hpcb5wzc707qsswihdkp8zz5m3c9yl9cnn2whhw2"; # 2024-08-16
      v29-0-1 = _v "29.0.1" "1d1nb55jmfaks0pqga9yyy920f3pnk6909hlagjwanqwvzxq2zn4"; # 2024-07-09
      v28-3-0 = _v "28.3.0" "1nahyic3gwcgmlh5c4k0wbd3bdraggkp0c51kc75yq192hfkn6n1"; # 2024-06-14
      v27-0-2 = _v "27.0.2" "1mfbyh1ihknkxb1nmasikz7cy6vqbw8741hqdxmh8p1myvldk59k"; # 2024-04-12
      v26-1-0 = _v "26.1.0" "0cmmfx908dli28l36dx38mmw67hajzxymm5fchgs8cfry6gkg4jl"; # 2024-02-19
      v25-0-0 = _v "25.0.0" "0lwix9b6yr7mnlyljqn3530qn8r9i8vazazs00xiccvs82fhmbxr"; # 2023-10-23
      v24-0-0 = _v "24.0.0" "0az08cmyw3h2xh6yhlfp8aw3mrvfz1wv4jg1zqk52zbsjqzczk0l"; # 2023-08-10
      v23-2-0 = _v "23.2.0" "173ncgqi863nbvqvrjfrg9q0ilahswgcyznaiznhxbrxcjisjwqi"; # 2023-07-27
      v22-3-0 = _v "22.3.0" "0x9i5fkz2b00a3zhy9r2501df92wk878spqqplwiq11xn1wl4bxb";
      v21-2-1 = _v "21.2.1" "0inbl2n0yg0r2gnj4hqhbwk0y2fixa2z74lvifff41z2qz8bzm0k";
      v20-8-0 = _v "20.8.0" "1fqyhh55b8l56yq5372g2s4m1kwggh0xln77s1yckdy9pbfgiw78";
      v19-0-4 = _v "19.0.4" "1j0fgr2jmi8p2zxf7k8764lidmw96vqcy5y821hlr66a8l1cp1iy";
      v12-0-7 = _v "12.0.7" "1hy7ikx2zcwyh8904h792f63mz689bxnwqps4wxsbmw626p3wz8p";
      v10-33-0 = _v "10.33.0" "02692bgy5g1p7v9fdclb2fmxxv364kv7xbw2b1z5c2r1wj271g6k";
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
      , exposeMetrics ? false
      , portMetrics ? 9100
      , allowExternalNameServices ? false
      , extraValues ? { }
      , additionalArguments ? [ ]
      }:
      let
        pre27 = (builtins.compareVersions version "27.0.0") == -1;
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
          ] else [ ]) ++ (if allowExternalNameServices then [
            "--providers.kubernetescrd.allowexternalnameservices=true"
            "--providers.kubernetesingress.allowexternalnameservices=true"
          ] else [ ]) ++ additionalArguments;
          deployment = {
            inherit replicas;
          };
          globalArguments = [ ];
          ports = {
            traefik = {
              exposedPort = portTraefik;
              protocol = proto.tcp;
            } // (if pre27 then { expose = exposeTraefik; } else { expose.default = exposeTraefik; });
            web = {
              exposedPort = portHttp;
              port = 8000;
              protocol = proto.tcp;
              # redirectTo = "websecure";
            } // (if pre27 then { expose = exposeHttp; } else { expose.default = exposeHttp; });
            websecure = {
              exposedPort = portHttps;
              port = 8443;
              protocol = proto.tcp;
            } // (if pre27 then { expose = exposeHttps; } else { expose.default = exposeHttps; });
            metrics = {
              expose = exposeMetrics;
              exposedPort = portMetrics;
              port = 9100;
              protocol = proto.tcp;
            } // (if pre27 then { expose = exposeMetrics; } else { expose.default = exposeMetrics; });
          };
          providers = {
            kubernetesCRD = {
              inherit allowExternalNameServices;
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
          text = toYAML (values // extraValues);
        };
      in
      hex.k8s.helm.build {
        inherit name namespace sets version sha256 extraFlags forceNamespace sortYaml;
        url = chart_url version;
        values = [ values_file ];
      };

    # middlewares https://doc.traefik.io/traefik/middlewares/http/overview/
    middleware = rec {
      build = args: toYAMLDoc (setup args);
      setup = { name, spec, kind ? "Middleware", apiVersion ? "traefik.containo.us/v1alpha1", extraSpec ? { } }: {
        inherit kind apiVersion spec;
        metadata = {
          inherit name;
        };
      } // extraSpec;
      _ = {
        add_prefix = { prefix, name ? "add-prefix", extraSpec ? { } }: build {
          inherit name extraSpec;
          spec = {
            addPrefix = {
              inherit prefix;
            };
          };
        };
        compress = { name ? "compress", extraSpec ? { } }: build {
          inherit name extraSpec;
          spec = {
            compress = { };
          };
        };
        default_index = { name ? "default-index", extraSpec ? { } }: build {
          inherit name extraSpec;
          spec = {
            replacePathRegex = {
              regex = "^/$";
              replacement = "/index.html";
            };
          };
        };
        ip_whitelist = { ips, name ? "ip-whitelist", extraSpec ? { } }: build {
          inherit name extraSpec;
          spec = {
            ipWhiteList.sourceRange = ips;
          };
        };
        strip_prefix = { prefixes, name ? "strip-prefix", extraSpec ? { } }: build {
          inherit name extraSpec;
          spec = {
            stripPrefix = {
              inherit prefixes;
            };
          };
        };
      };
    };

    # ingressroute https://doc.traefik.io/traefik/v2.2/routing/providers/kubernetes-crd/#kind-ingressroute
    ingress_route = rec {
      constants = { };
      build = args: toYAMLDoc (setup args);
      setup =
        { name
        , domain
        , regex ? false
        , port ? 80
        , namespace ? "default"
        , service ? name
        , serviceScheme ? if port == 443 then "https" else "http"
        , extraService ? { }
        , extraServices ? [ ]
        , internal ? true
        , secretName ? ""
        , labels ? [ ]
        , middlewares ? [ ]
        , extraRule ? { }
        , extraRoutes ? [ ]
        , extraSpec ? { }
        , ingressRouteNamespace ? "default"
        , pre23 ? false
        , apiVersion ? if pre23 then "traefik.containo.us/v1alpha1" else "traefik.io/v1alpha1"
        }:
        let
          secure = (builtins.stringLength secretName) > 0;
          entrypoint = if secure then "websecure" else "web";
          tlsOptions =
            if secure then {
              tls = {
                inherit secretName;
              };
            } else { };
          # route = {kind ? "Rule", match ? "Host(`${host}`)", host ? ""}: {};
        in
        {
          inherit apiVersion;
          kind = "IngressRoute";
          metadata = {
            inherit name;
            namespace = ingressRouteNamespace;
            annotations = {
              "kubernetes.io/ingress.class" = if internal then "traefik-internal" else "traefik";
            } // hex.annotations;
            ${ifNotEmptyList labels "labels"} = labels;
          };
          spec = {
            entryPoints = [ entrypoint ];
            routes = [
              ({
                ${ifNotEmptyList middlewares "middlewares"} = middlewares;
                kind = "Rule";
                match = "Host${if regex then "Regexp" else ""}(`${domain}`)";
                services = [
                  ({
                    inherit namespace port;
                    name = service;
                    passHostHeader = true;
                    scheme = serviceScheme;
                  } // extraService)
                ] ++ extraServices;
              } // extraRule)
            ] ++ extraRoutes;
          } // tlsOptions // extraSpec;
        };
    };
  };
in
traefik
