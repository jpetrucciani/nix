# This module allows us to create best-practices, all-inclusive k8s services with a set of powerful nix functions.
{ hex, pkgs, ... }:
let
  inherit (hex) attrIf ifNotNull ifNotEmptyList ifNotEmptyAttr toYAMLDoc;
  inherit (hex) boolToString concatMapStrings concatStringsSep filter removePrefix;
  inherit (pkgs.lib.attrsets) mapAttrsToList;

  defaults = {
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
    nodeAffinity = { labels, hard ? false, topologyKey ? "kubernetes.io/hostname" }:
      let
        _type = if hard then "required" else "preferred";
        affinityType = "${_type}DuringSchedulingIgnoredDuringExecution";
      in
      {
        podAntiAffinity = {
          ${affinityType} = [
            {
              podAffinityTerm = {
                inherit topologyKey;
                labelSelector = {
                  matchExpressions = mapAttrsToList (k: v: { key = k; operator = "In"; values = [ v ]; }) labels;
                };
              };
              weight = 100;
            }
          ];
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
      , serviceAccountToken ? false
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
      , ephemeralStorageRequest ? null
      , ephemeralStorageLimit ? null
      , command ? null
      , args ? null
      , env ? [ ]
      , envAttrs ? { }
      , envFrom ? [ ]
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
      , egressPolicy ? defaults.egressPolicy
      , ingressPolicy ? defaults.ingressPolicy
      , daemonSet ? false
      , suffix ? ""
      , depSuffix ? "${suffix}"
      , saSuffix ? "-service-account${suffix}"
      , npSuffix ? "-policy${suffix}"
      , rbSuffix ? "-role-binding-view${suffix}"
      , hpaSuffix ? "-hpa${suffix}"
      , serviceSuffix ? "-service${suffix}"
      , ingressSuffix ? "-ingress${suffix}"
      , tsSuffix ? "-ts${suffix}"
      , pre1_18 ? false
      , host ? null
      , extraContainer ? { }
      , extraServiceAnnotations ? { }
      , extraIngressAnnotations ? { }
      , extraPodAnnotations ? { }
      , imagePullSecrets ? [ ]
      , ingressTLSSecret ? ""
      , softAntiAffinity ? false
      , hardAntiAffinity ? false
      , disableHttp ? true
      , tailscaleSidecar ? false
      , tailscale_image_base ? hex.k8s.tailscale.defaults.tailscale_image_base
      , tailscale_image_tag ? hex.k8s.tailscale.defaults.tailscale_image_tag
      , hostAliases ? [ ]
      , appArmor ? "unconfined"
      , extraDep ? { }
      , extraSA ? { }
      , extraNP ? { }
      , extraRB ? { }
      , extraHPA ? { }
      , extraSvc ? { }
      , extraIng ? { }
      , __init ? false
      }:
      let
        affinity =
          if softAntiAffinity then defaults.nodeAffinity { inherit labels; }
          else if hardAntiAffinity then defaults.nodeAffinity { inherit labels; hard = true; }
          else { };
        sa = (components.service-account {
          inherit name namespace saSuffix imagePullSecrets;
        }) // extraSA;
        sa-token = components.service-account-token {
          inherit name namespace saSuffix;
        };
        rb = (components.role-binding {
          inherit name namespace rbSuffix saSuffix;
        }) // extraRB;
        ts_r = hex.k8s.tailscale.role { inherit namespace; name = "${name}${tsSuffix}"; };
        ts_rb = {
          apiVersion = "rbac.authorization.k8s.io/v1";
          kind = "RoleBinding";
          metadata = {
            name = "${name}-tailscale";
            inherit namespace;
          };
          roleRef = {
            apiGroup = "rbac.authorization.k8s.io";
            kind = "Role";
            name = "${name}${tsSuffix}";
          };
          subjects = [
            {
              kind = "ServiceAccount";
              name = "${name}${saSuffix}";
            }
          ];
        };
        ts_secret = hex.k8s.tailscale.secret { inherit namespace; name = "${name}${tsSuffix}"; };
        np = (components.network-policy {
          inherit name namespace labels npSuffix;
          egress = egressPolicy;
          ingress = ingressPolicy;
        }) // extraNP;
        dep = (components.deployment {
          inherit name namespace labels image replicas revisionHistoryLimit maxSurge maxUnavailable depSuffix saSuffix daemonSet lifecycle imagePullSecrets affinity;
          inherit cpuRequest memoryRequest ephemeralStorageRequest cpuLimit memoryLimit ephemeralStorageLimit command args volumes subdomain nodeSelector livenessProbe readinessProbe securityContext;
          inherit env envAttrs envFrom extraContainer extraPodAnnotations appArmor tailscaleSidecar tailscale_image_base tailscale_image_tag tsSuffix hostAliases __init;
        }) // extraDep;
        hpa = (components.hpa { inherit name namespace labels min max cpuUtilization hpaSuffix; }) // extraHPA;
        svc =
          (if nodePort then components.nodeport-service { inherit name namespace labels port serviceSuffix extraServiceAnnotations; } else
          if loadBalancer then
            components.lb-service { inherit name namespace labels port altPort ip serviceSuffix extraServiceAnnotations; } else
            components.service { inherit name namespace labels port altPort serviceSuffix extraServiceAnnotations; }) // extraSvc;
        ing = (components.ingress { inherit name namespace port ingressSuffix serviceSuffix pre1_18 host extraIngressAnnotations disableHttp; tls = ingressTLSSecret; }) // extraIng;
      in
      ''
        ${if serviceAccountToken then toYAMLDoc sa-token else ""}
        ${if serviceAccount then toYAMLDoc sa else ""}
        ${if roleBinding then toYAMLDoc rb else ""}
        ${if tailscaleSidecar then toYAMLDoc ts_r else ""}
        ${if tailscaleSidecar then toYAMLDoc ts_rb else ""}
        ${if tailscaleSidecar then toYAMLDoc ts_secret else ""}
        ${toYAMLDoc dep}
        ${if service then toYAMLDoc svc else ""}
        ${if autoscale then toYAMLDoc hpa else ""}
        ${if networkPolicy then toYAMLDoc np else ""}
        ${if ingress then toYAMLDoc ing else ""}
      '';
    components = {
      volumes = {
        tmp = {
          name = "tmp";
          mountPath = "/tmp";
          emptyDir = true;
          readOnly = false;
        };
      };
      service-account-token = { name, namespace ? "default", saSuffix ? "-sa" }: {
        apiVersion = "v1";
        kind = "Secret";
        metadata = {
          inherit namespace;
          annotations = {
            "kubernetes.io/service-account.name" = "${name}${saSuffix}";
          };
          name = "${name}${saSuffix}-token";
        };
        type = "kubernetes.io/service-account-token";
      };
      service-account = { name, namespace ? "default", saSuffix ? "-sa", imagePullSecrets ? [ ] }: {
        apiVersion = "v1";
        kind = "ServiceAccount";
        metadata = {
          inherit namespace;
          annotations = { } // hex.annotations;
          name = "${name}${saSuffix}";
        };
        ${ifNotEmptyList imagePullSecrets "imagePullSecrets"} = imagePullSecrets;
      };
      role = { name, rules, namespace ? "default", extraConfig ? { } }: {
        inherit rules;
        apiVersion = "rbac.authorization.k8s.io/v1";
        kind = "Role";
        metadata = {
          inherit name namespace;
        };
      } // extraConfig;
      role-binding = { name, namespace ? "default", rbSuffix ? "-rb-view", saSuffix ? "-sa", extraConfig ? { } }: {
        apiVersion = "rbac.authorization.k8s.io/v1";
        kind = "RoleBinding";
        metadata = {
          inherit namespace;
          name = "${name}${rbSuffix}";
          annotations = { } // hex.annotations;
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
      } // extraConfig;
      network-policy =
        { name
        , labels
        , egress ? defaults.egressPolicy
        , ingress ? defaults.ingressPolicy
        , namespace ? "default"
        , npSuffix ? "-np"
        , extraConfig ? { }
        }: {
          apiVersion = "networking.k8s.io/v1";
          kind = "NetworkPolicy";
          metadata = {
            inherit namespace;
            name = "${name}${npSuffix}";
            annotations = { } // hex.annotations;
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
        } // extraConfig;

      hpa = { name, labels, namespace ? "default", min ? 2, max ? 4, cpuUtilization ? 80, hpaSuffix ? "-hpa", extraConfig ? { } }: {
        apiVersion = "autoscaling/v1";
        kind = "HorizontalPodAutoscaler";
        metadata = {
          inherit labels namespace;
          name = "${name}${hpaSuffix}";
          annotations = { } // hex.annotations;
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
      } // extraConfig;

      service =
        { name
        , labels
        , port ? 443
        , altPort ? null
        , namespace ? "default"
        , serviceSuffix ? "-service"
        , extraServiceAnnotations ? { }
        , extraConfig ? { }
        }: {
          apiVersion = "v1";
          kind = "Service";
          metadata = {
            inherit namespace;
            labels = {
              name = "${name}${serviceSuffix}";
            };
            name = "${name}${serviceSuffix}";
            annotations = { } // hex.annotations // extraServiceAnnotations;
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
        } // extraConfig;

      nodeport-service =
        { name
        , labels
        , port ? 8080
        , namespace ? "default"
        , serviceSuffix ? "-service"
        , extraServiceAnnotations ? { }
        , extraConfig ? { }
        }: {
          apiVersion = "v1";
          kind = "Service";
          metadata = {
            inherit namespace;
            labels = {
              name = "${name}${serviceSuffix}";
            };
            name = "${name}${serviceSuffix}";
            annotations = { } // hex.annotations // extraServiceAnnotations;
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
        } // extraConfig;

      lb-service =
        { name
        , labels
        , ip
        , port ? 443
        , altPort ? null
        , namespace ? "default"
        , serviceSuffix ? "-service"
        , extraServiceAnnotations ? { }
        , extraConfig ? { }
        }: {
          apiVersion = "v1";
          kind = "Service";
          metadata = {
            inherit namespace;
            labels = {
              name = "${name}${serviceSuffix}";
            };
            name = "${name}${serviceSuffix}";
            annotations = { } // hex.annotations // extraServiceAnnotations;
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
        } // extraConfig;

      deployment =
        let
          volumeDef = { name, secret ? null, hostPath ? null, configMap ? null, emptyDir ? false, items ? null, pvc ? null, ... }: {
            inherit name;
            ${ifNotNull pvc "persistentVolumeClaim"} = {
              claimName = pvc;
            };
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
        , ephemeralStorageRequest ? null
        , ephemeralStorageLimit ? null
        , namespace ? "default"
        , depSuffix ? ""
        , saSuffix ? "-sa"
        , tsSuffix ? "-ts"
        , command ? null
        , args ? null
        , env ? [ ]
        , envAttrs ? { }
        , envFrom ? [ ]
        , volumes ? [ ]
        , subdomain ? null
        , nodeSelector ? null
        , livenessProbe ? null
        , readinessProbe ? null
        , securityContext ? null
        , lifecycle ? null
        , daemonSet ? false
        , imagePullSecrets ? [ ]
        , affinity ? { }
        , extraContainer ? { }
        , extraPodAnnotations ? { }
        , appArmor ? "unconfined"
        , tailscaleSidecar ? false
        , tailscale_tags ? [ ]
        , default_tailscale_tags ? [ "k8s" "proxy" ]
        , all_tailscale_tags ? tailscale_tags ++ default_tailscale_tags
        , tailscale_image_base ? hex.k8s.tailscale.defaults.tailscale_image_base
        , tailscale_image_tag ? hex.k8s.tailscale.defaults.tailscale_image_tag
        , tailscale_stateful_filtering ? false
        , tailscale_extra_args ? [ ]
        , hostAliases ? [ ]
        , __init ? false
        }:
        let
          joinTags = concatMapStrings (x: ",tag:${x}");
          depName = "${name}${depSuffix}";
          _tags = removePrefix "," (joinTags all_tailscale_tags);
          advertise_tags_flag = if builtins.length all_tailscale_tags != 0 then "--advertise-tags=${_tags}" else null;
          stateful_filtering = "--stateful-filtering=${boolToString tailscale_stateful_filtering}";
          _extra_args = filter (x: x != null) ([
            advertise_tags_flag
            stateful_filtering
          ] ++ tailscale_extra_args);
          ts_extra_args = concatStringsSep " " _extra_args;
        in
        {
          apiVersion = "apps/v1";
          kind = if daemonSet then "DaemonSet" else "Deployment";
          metadata = {
            inherit namespace labels;
            name = depName;
            annotations = { } // hex.annotations;
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
                  ${ifNotNull appArmor "container.apparmor.security.beta.kubernetes.io/${name}"} = appArmor;
                } // hex.annotations // extraPodAnnotations;
              };
              spec = {
                ${ifNotEmptyAttr affinity "affinity"} = affinity;
                ${ifNotEmptyList imagePullSecrets "imagePullSecrets"} = imagePullSecrets;
                ${ifNotNull subdomain "subdomain"} = subdomain;
                ${ifNotNull nodeSelector "nodeSelector"} = nodeSelector;
                containers = [
                  ({
                    inherit image name;
                    env = env ++ (hex.envAttrToNVP envAttrs);
                    ${ifNotEmptyList envFrom "envFrom"} = envFrom;
                    ${ifNotNull command "command"} = if __init then [ "tail" ] else if builtins.isString command then [ command ] else command;
                    ${ifNotNull args "args"} = if __init then [ "-f" "/dev/null" ] else args;
                    ${ifNotNull livenessProbe "livenessProbe"} = livenessProbe;
                    ${ifNotNull readinessProbe "readinessProbe"} = readinessProbe;
                    ${ifNotNull securityContext "securityContext"} = securityContext;
                    ${ifNotNull lifecycle "lifecycle"} = lifecycle;

                    imagePullPolicy = "Always";
                    resources = {
                      ${if (memoryRequest != null || cpuRequest != null || ephemeralStorageRequest != null) then "requests" else null} = {
                        ${ifNotNull cpuRequest "cpu"} = cpuRequest;
                        ${ifNotNull memoryRequest "memory"} = memoryRequest;
                        ${ifNotNull ephemeralStorageRequest "ephemeral-storage"} = ephemeralStorageRequest;
                      };
                      ${if (memoryLimit != null || cpuLimit != null || ephemeralStorageLimit != null) then "limits" else null} = {
                        ${ifNotNull memoryLimit "memory"} = memoryLimit;
                        ${ifNotNull cpuLimit "cpu"} = cpuLimit;
                        ${ifNotNull ephemeralStorageLimit "ephemeral-storage"} = ephemeralStorageLimit;
                      };
                    };
                    ${ifNotEmptyList volumes "volumeMounts"} = map volumeMountDef volumes;
                  } // extraContainer)
                ] ++ (if tailscaleSidecar then [{
                  name = "ts";
                  image = "${tailscale_image_base}:${tailscale_image_tag}";
                  env = hex.envAttrToNVP {
                    TS_KUBE_SECRET = "${name}${tsSuffix}";
                    TS_USERSPACE = "false";
                    TS_EXTRA_ARGS = ts_extra_args;
                  };
                  securityContext.capabilities.add = [ "NET_ADMIN" ];
                }] else [ ]);
                serviceAccountName = "${name}${saSuffix}";
                ${ifNotEmptyList volumes "volumes"} = map volumeDef volumes;
                ${ifNotEmptyList hostAliases "hostAliases"} = hostAliases;
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
        , disableHttp ? true
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
            annotations = { } // (if disableHttp then {
              "kubernetes.io/ingress.allow-http" = "false";
            } else { }) // extraIngressAnnotations;
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

      pvc =
        { name
        , namespace ? "default"
        , accessModes ? [ "ReadWriteOnce" ]
        , storage ? "10Gi"
        , storageClass ? "standard"
        , extra ? { }
        }: {
          apiVersion = "v1";
          kind = "PersistentVolumeClaim";
          metadata = {
            inherit name namespace;
          };
          spec = {
            inherit accessModes;
            resources = {
              requests = {
                inherit storage;
              };
            };
            storageClassName = storageClass;
          };
        } // extra;
    };
  };
in
services
