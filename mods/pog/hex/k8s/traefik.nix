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
      latest = v28-3-0;
      v28-3-0 = _v "28.3.0" "1nahyic3gwcgmlh5c4k0wbd3bdraggkp0c51kc75yq192hfkn6n1"; # 2024-06-14
      v28-2-0 = _v "28.2.0" "1bribwj467nbrfz64dgja4583w5vjams2g3b0qvmqs42xc0xr87r"; # 2024-05-31
      v28-1-0 = _v "28.1.0" "1xp1qdwz4y99sq0wwyxw5grbfv8fvpdnis00hxd27nvwfy5smhl7"; # 2024-05-22
      v28-0-0 = _v "28.0.0" "1p4g12n3ngkmgifmwbvrbdqi4068j3dnwwwm38k2s6w6f9vixmj5"; # 2024-04-30
      v27-0-2 = _v "27.0.2" "1mfbyh1ihknkxb1nmasikz7cy6vqbw8741hqdxmh8p1myvldk59k"; # 2024-04-12
      v26-1-0 = _v "26.1.0" "0cmmfx908dli28l36dx38mmw67hajzxymm5fchgs8cfry6gkg4jl"; # 2024-02-19
      v26-0-0 = _v "26.0.0" "14crjr25zanrcq4mji9c01rfrcdqciz8nxw7yf169h2iljbp380r"; # 2023-12-05
      v25-0-0 = _v "25.0.0" "0lwix9b6yr7mnlyljqn3530qn8r9i8vazazs00xiccvs82fhmbxr"; # 2023-10-23
      v24-0-0 = _v "24.0.0" "0az08cmyw3h2xh6yhlfp8aw3mrvfz1wv4jg1zqk52zbsjqzczk0l"; # 2023-08-10
      v23-2-0 = _v "23.2.0" "173ncgqi863nbvqvrjfrg9q0ilahswgcyznaiznhxbrxcjisjwqi"; # 2023-07-27
      v23-1-0 = _v "23.1.0" "05f5bnn6lqk979flm7dqkxcv6f4vcl6314dmj1j7bss8s1fvh45h"; # 2023-06-06
      v23-0-1 = _v "23.0.1" "1mcvpv6d0z22mmk91vxn2wm7gdrx4s7q72mq2v3sy8s06a32paap"; # 2023-04-28
      v23-0-0 = _v "23.0.0" "046r08k93hxl5b80r606dhlihl0gg6hnk67kslidcj0vjb64qnwq"; # 2023-04-26
      v22-3-0 = _v "22.3.0" "0x9i5fkz2b00a3zhy9r2501df92wk878spqqplwiq11xn1wl4bxb";
      v21-2-1 = _v "21.2.1" "0inbl2n0yg0r2gnj4hqhbwk0y2fixa2z74lvifff41z2qz8bzm0k";
      v21-1-0 = _v "21.1.0" "0i6wywgp930l52286v3f1f70bymfmqpqi6lwmi1csq6pb5zckrap";
      v21-0-0 = _v "21.0.0" "1kgplwfl729mpx6bm90mh42kds0h4q9r3frry4jb4g61fmy5xxpw";
      v20-8-0 = _v "20.8.0" "1fqyhh55b8l56yq5372g2s4m1kwggh0xln77s1yckdy9pbfgiw78";
      v20-7-0 = _v "20.7.0" "1szwfxss3lv7a7jsfl09zq3igfsn58rf555fw3j96jks0hkskip9";
      v20-6-0 = _v "20.6.0" "0a590r12byk4l216pdrzb6n500xv9zii77xhbw5s52f9ih2kl3jw";
      v20-5-3 = _v "20.5.3" "04q0hkm9a0l53lacmb2dlicphv69gb9fc1ybfbbd4y97zy12iadg";
      v20-4-1 = _v "20.4.1" "1mpcmrs6jny1p2r4v15h5q7b4k3v0cj2p5zjq6mvah0988wav3jn";
      v20-3-1 = _v "20.3.1" "1nrkh80qafmnwl00j16n04h737jgpd30yxr9r2g89l83p6a4v9xq";
      v20-2-1 = _v "20.2.1" "0yhnhcvp0pjfc4qsgsi4b9hzxavnaigazyyc4874jd5xs3z4gwmf";
      v20-1-1 = _v "20.1.1" "1nsali7nbyrjx99pqqcs7y0y9fhcg4xla3hpy11wn1axdlr7mr3w";
      v20-0-0 = _v "20.0.0" "09pj1xg7ldprlbcp3jmbiw1f395llf0vbaa9xxffiwh56f5nc8mk";
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
          ] else [ ]) ++ (if allowExternalNameServices then [
            "--providers.kubernetescrd.allowexternalnameservices=true"
            "--providers.kubernetesingress.allowexternalnameservices=true"
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
            metrics = {
              expose = exposeMetrics;
              exposedPort = portMetrics;
              port = 9100;
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
