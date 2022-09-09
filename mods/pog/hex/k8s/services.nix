{ hex, pkgs }:
let
  inherit (hex) attrIf ifNotNull ifNotEmptyList toYAML;

  defaults = {
    annotations = {
      source = "hexrender";
    };
    egressPolicy = [
      {
        to = [
          {
            ipBlock = {
              cidr = "0.0.0.0/0";
            };
          }
        ];
      }
    ];
    ingressPolicy = [
      {
        from = [
          {
            ipBlock = {
              cidr = "0.0.0.0/0";
            };
          }
        ];
      }
    ];
    checks = {
      liveness =
        { path ? "/healthz"
        , command ? [ "true" ]
        , port ? 8080
        , http ? true
        , scheme ? "http"
        , failureThreshold ? 3
        , initialDelaySeconds ? 4
        , periodSeconds ? 4
        , successThreshold ? 1
        , timeoutSeconds ? 2
        , httpHeaders ? [ ]
        }:
        if http then {
          httpGet = {
            inherit path port scheme;
            ${ifNotEmptyList httpHeaders "httpHeaders"} = httpHeaders;
          };
          inherit failureThreshold initialDelaySeconds periodSeconds successThreshold timeoutSeconds;
        } else {
          inherit failureThreshold initialDelaySeconds periodSeconds successThreshold timeoutSeconds;
          exec = { inherit command; };
        };

    };
  };

  services = rec {
    build =
      { name
      , labels
      , image
      , namespace ? "default"
      , min ? replicas
      , max ? replicas * 2
      , autoscale ? true
      , networkPolicy ? true
      , serviceAccount ? true
      , roleBinding ? true
      , port ? 443
      , altPort ? null
      , cpuUtilization ? 75
      , replicas ? 2
      , revisionHistoryLimit ? 2
      , maxSurge ? 1
      , maxUnavailable ? 1
      , cpuRequest ? "400m"
      , cpuLimit ? null
      , memoryRequest ? "1Gi"
      , memoryLimit ? null
      , command ? null
      , args ? null
      , env ? [ ]
      , volumes ? [ ]
      , ip ? null
      , service ? true
      , loadBalancer ? false
      , ingress ? false
      , nodePort ? false
      , subdomain ? null
      , nodeSelector ? null
      , lifecycle ? null
      , livenessProbe ? null
      , readinessProbe ? null
      , securityContext ? null
      , strategy ? null
      , egressPolicy ? defaults.egressPolicy
      , ingressPolicy ? defaults.ingressPolicy
      , daemonSet ? false
      , china ? false
      , suffix ? ""
      , depSuffix ? "${suffix}"
      , saSuffix ? "-service-account${suffix}"
      , npSuffix ? "-policy${suffix}"
      , rbSuffix ? "-role-binding-view${suffix}"
      , hpaSuffix ? "-hpa${suffix}"
      , serviceSuffix ? "-service${suffix}"
      , ingressSuffix ? "-ingress${suffix}"
      , pre1_18 ? false
      , host ? null
      , extraServiceAnnotations ? { }
      , extraIngressAnnotations ? { }
      , imagePullSecrets ? [ ]
      , ingressTLSSecret ? ""
      }:
      let
        sa = components.service-account { inherit name namespace china saSuffix imagePullSecrets; };
        rb = components.role-binding { inherit name namespace rbSuffix saSuffix; };
        np = components.network-policy {
          inherit name namespace labels npSuffix;
          egress = egressPolicy;
          ingress = ingressPolicy;
        };
        dep = components.deployment {
          inherit name namespace labels image replicas revisionHistoryLimit maxSurge maxUnavailable depSuffix saSuffix daemonSet lifecycle imagePullSecrets;
          inherit cpuRequest memoryRequest cpuLimit memoryLimit command args env volumes subdomain nodeSelector livenessProbe readinessProbe securityContext pre1_18;
        };
        hpa = components.hpa { inherit name namespace labels min max cpuUtilization hpaSuffix; };
        svc =
          if nodePort then components.nodeport-service { inherit name namespace labels port serviceSuffix extraServiceAnnotations; } else
          if loadBalancer then
            components.lb-service { inherit name namespace labels port altPort ip serviceSuffix extraServiceAnnotations; } else
            components.service { inherit name namespace labels port altPort serviceSuffix extraServiceAnnotations; };
        ing = components.ingress { inherit name namespace port ingressSuffix serviceSuffix pre1_18 host extraIngressAnnotations; tls = ingressTLSSecret; };
      in
      ''
        ${if serviceAccount then "---\n${toYAML sa}" else ""}
        ${if roleBinding then "---\n${toYAML rb}" else ""}
        ---
        ${toYAML dep}
        ${if service then "---\n${toYAML svc}" else ""}
        ${if autoscale then "---\n${toYAML hpa}" else ""}
        ${if networkPolicy then "---\n${toYAML np}" else ""}
        ${if ingress then "---\n${toYAML ing}" else ""}
      '';
    components = rec {
      service-account = { name, namespace ? "default", china ? false, saSuffix ? "-sa", imagePullSecrets ? [ ] }: {
        apiVersion = "v1";
        kind = "ServiceAccount";
        metadata = {
          name = "${name}${saSuffix}";
          annotations = { } // defaults.annotations;
        };
        ${ifNotEmptyList imagePullSecrets "imagePullSecrets"} = imagePullSecrets;
      };
      role = { name, rules, namespace ? "default" }: {
        inherit rules;
        apiVersion = "rbac.authorization.k8s.io/v1";
        kind = "Role";
        metadata = {
          inherit name namespace;
        };
      };
      role-binding = { name, namespace ? "default", rbSuffix ? "-rb-view", saSuffix ? "-sa" }: {
        apiVersion = "rbac.authorization.k8s.io/v1";
        kind = "RoleBinding";
        metadata = {
          inherit namespace;
          name = "${name}${rbSuffix}";
          annotations = { } // defaults.annotations;
        };
        roleRef = {
          apiGroup = "rbac.authorization.k8s.io";
          kind = "ClusterRole";
          name = "view";
        };
        subjects = [
          {
            inherit namespace;
            kind = "ServiceAccount";
            name = "${name}${saSuffix}";
          }
        ];
      };
      network-policy = { name, labels, egress ? defaults.egressPolicy, ingress ? defaults.ingressPolicy, namespace ? "default", npSuffix ? "-np" }: {
        apiVersion = "networking.k8s.io/v1";
        kind = "NetworkPolicy";
        metadata = {
          inherit namespace;
          name = "${name}${npSuffix}";
          annotations = { } // defaults.annotations;
        };
        spec = {
          inherit egress ingress;
          podSelector = {
            matchLabels = labels;
          };
          policyTypes = [
            "Ingress"
            "Egress"
          ];
        };
      };

      hpa = { name, labels, namespace ? "default", min ? 2, max ? 4, cpuUtilization ? 80, hpaSuffix ? "-hpa" }: {
        apiVersion = "autoscaling/v1";
        kind = "HorizontalPodAutoscaler";
        metadata = {
          inherit labels namespace;
          name = "${name}${hpaSuffix}";
          annotations = { } // defaults.annotations;
        };
        spec = {
          maxReplicas = max;
          minReplicas = min;
          scaleTargetRef = {
            inherit name;
            apiVersion = "apps/v1";
            kind = "Deployment";
          };
          targetCPUUtilizationPercentage = cpuUtilization;
        };
      };

      service = { name, labels, port ? 443, altPort ? null, namespace ? "default", serviceSuffix ? "-service", extraServiceAnnotations ? { } }: {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          inherit namespace;
          labels = {
            name = "${name}${serviceSuffix}";
          };
          name = "${name}${serviceSuffix}";
          annotations = { } // defaults.annotations // extraServiceAnnotations;
        };
        spec = {
          ports = [
            {
              inherit port;
              name = "application";
              targetPort = port;
              protocol = "TCP";
            }
          ] ++ (if altPort != null then [{
            port = altPort;
            name = "application-alt";
            targetPort = altPort;
            protocol = "TCP";
          }] else [ ]);
          selector = labels;
          type = "ClusterIP";
        };
      };

      nodeport-service = { name, labels, port ? 8080, namespace ? "default", serviceSuffix ? "-service", extraServiceAnnotations ? { } }: {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          inherit namespace;
          labels = {
            name = "${name}${serviceSuffix}";
          };
          name = "${name}${serviceSuffix}";
          annotations = { } // defaults.annotations // extraServiceAnnotations;
        };
        spec = {
          ports = [
            {
              inherit port;
              name = "application";
              targetPort = port;
              protocol = "TCP";
            }
          ];
          selector = labels;
          type = "NodePort";
        };
      };

      lb-service = { name, labels, ip, port ? 443, altPort ? null, namespace ? "default", serviceSuffix ? "-service", extraServiceAnnotations ? { } }: {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          inherit namespace;
          labels = {
            name = "${name}${serviceSuffix}";
          };
          name = "${name}${serviceSuffix}";
          annotations = { } // defaults.annotations // extraServiceAnnotations;
        };
        spec = {
          ports = [
            {
              inherit port;
              name = "application";
              targetPort = port;
              protocol = "TCP";
            }
          ] ++ (if altPort != null then [{
            port = altPort;
            name = "application-alt";
            targetPort = altPort;
            protocol = "TCP";
          }] else [ ]);
          selector = labels;
          type = "LoadBalancer";
          loadBalancerIP = ip;
          externalTrafficPolicy = "Local";
          externalIPs = [ ip ];
        };
      };

      deployment =
        let
          volumeDef = { name, secret ? null, hostPath ? null, configMap ? null, emptyDir ? false, items ? null, ... }: {
            inherit name;
            ${ifNotNull secret "secret"} = {
              secretName = secret;
              ${ifNotNull items "items"} = items;
            };
            ${ifNotNull configMap "configMap"}.name = configMap;
            ${ifNotNull hostPath "hostPath"}.path = hostPath;
            ${attrIf emptyDir "emptyDir"} = { };
          };
          volumeMountDef = { name, mountPath, readOnly ? true, ... }: {
            inherit name mountPath readOnly;
          };
        in
        { name
        , labels
        , image
        , replicas ? 2
        , revisionHistoryLimit ? 2
        , maxSurge ? 1
        , maxUnavailable ? 1
        , cpuRequest ? "400m"
        , cpuLimit ? null
        , memoryRequest ? "1Gi"
        , memoryLimit ? null
        , namespace ? "default"
        , depSuffix ? ""
        , saSuffix ? "-sa"
        , command ? null
        , args ? null
        , env ? [ ]
        , volumes ? [ ]
        , subdomain ? null
        , nodeSelector ? null
        , livenessProbe ? null
        , readinessProbe ? null
        , securityContext ? null
        , lifecycle ? null
        , daemonSet ? false
        , pre1_18 ? false
        , imagePullSecrets ? [ ]
        }:
        let
          depName = "${name}${depSuffix}";
        in
        {
          apiVersion = "apps/v1";
          kind = if daemonSet then "DaemonSet" else "Deployment";
          metadata = {
            inherit namespace labels;
            name = depName;
            annotations = { } // defaults.annotations;
          };
          spec = {
            inherit revisionHistoryLimit;
            selector = {
              matchLabels = labels;
            };
            ${if daemonSet then null else "replicas"} = replicas;
            ${if daemonSet then null else "strategy"} = {
              rollingUpdate = {
                inherit maxSurge maxUnavailable;
              };
              type = "RollingUpdate";
            };
            template = {
              metadata = {
                inherit namespace labels;
                name = depName;
                annotations = {
                  "container.apparmor.security.beta.kubernetes.io/${depName}" = "unconfined";
                } // defaults.annotations;
              };
              spec = {
                ${ifNotEmptyList imagePullSecrets "imagePullSecrets"} = imagePullSecrets;
                ${ifNotNull subdomain "subdomain"} = subdomain;
                ${ifNotNull nodeSelector "nodeSelector"} = nodeSelector;
                containers = [
                  {
                    inherit image name;
                    ${ifNotEmptyList env "env"} = env;
                    ${ifNotNull command "command"} = [ command ];
                    ${ifNotNull args "args"} = args;
                    ${ifNotNull livenessProbe "livenessProbe"} = livenessProbe;
                    ${ifNotNull readinessProbe "readinessProbe"} = readinessProbe;
                    ${ifNotNull securityContext "securityContext"} = securityContext;
                    ${ifNotNull lifecycle "lifecycle"} = lifecycle;

                    imagePullPolicy = "Always";
                    resources = {
                      requests = {
                        cpu = cpuRequest;
                        memory = memoryRequest;
                      };
                      ${if (memoryLimit != null || cpuLimit != null) then "limits" else null} = {
                        ${ifNotNull memoryLimit "memory"} = memoryLimit;
                        ${ifNotNull cpuLimit "cpu"} = cpuLimit;
                      };
                    };
                    ${ifNotEmptyList volumes "volumeMounts"} = map volumeMountDef volumes;
                  }
                ];
                serviceAccountName = "${name}${saSuffix}";
                ${ifNotEmptyList volumes "volumes"} = map volumeDef volumes;
              };
            };
          };
        };
      ingress =
        { name
        , port
        , tls
        , host ? null
        , namespace ? "default"
        , ingressSuffix ? "-ingress"
        , serviceSuffix ? "-service"
        , pre1_18 ? false
        , extraIngressAnnotations ? { }
        }: {
          apiVersion = if pre1_18 then "extensions/v1beta1" else "networking.k8s.io/v1";
          kind = "Ingress";
          metadata = {
            inherit namespace;
            name = "${name}${ingressSuffix}";
            labels = {
              name = "${name}${ingressSuffix}";
            };
            annotations = {
              "kubernetes.io/ingress.allow-http" = "false";
            } // extraIngressAnnotations;
          };
          spec = {
            ${if pre1_18 then null else "defaultBackend"} = {
              service = {
                name = "${name}${serviceSuffix}";
                port = {
                  number = port;
                };
              };
            };
            ${if pre1_18 then "rules" else null} = [
              {
                ${ifNotNull host "host"} = host;
                http = {
                  paths = [
                    {
                      backend = {
                        service = {
                          name = "${name}${serviceSuffix}";
                          port.number = port;
                        };
                      };
                      path = "/";
                      pathType = "ImplementationSpecific";
                    }
                  ];
                };
              }
            ];
            tls = [
              {
                ${ifNotNull host "hosts"} = [
                  host
                ];
                secretName = tls;
              }
            ];
          };
        };
    };
  };
in
services
