# This module contains helm charts under the [grafana](https://grafana.com/) observability umbrella. This includes things like [loki](https://github.com/grafana/loki), [mimir](https://github.com/grafana/mimir), and [oncall](https://github.com/grafana/oncall).
{ hex, ... }:
let
  inherit (hex) toYAML toYAMLDoc;
  _chart_url = { name, version, prefix ? "" }: "https://github.com/grafana/helm-charts/releases/download/${prefix}${name}-${version}/${name}-${version}.tgz";
  loki = rec {
    defaults = {
      name = "loki";
      chart_name = "loki";
      namespace = "loki";
    };
    chart = hex.k8s._.chart {
      inherit defaults;
      chart_url = version: _chart_url { inherit version; inherit (defaults) name; prefix = "helm-"; };
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v6-6-5;
      v6-6-5 = _v "6.6.5" "1mj0psnsswd04vaskxc6xqq0q0n5lir6j192ca1rgk3l8dlgyq9x"; # 2024-07-03
      v6-5-2 = _v "6.5.2" "00ydqpmgdhbclnian59nwlf4yjq4lqwmsfh0a7qm9267mxd37crc"; # 2024-05-10
      v6-4-2 = _v "6.4.2" "1yfk8m9yabyzv6lijymgf025069mbiswd4d55lldavzcqq96s5yk"; # 2024-04-30
      v6-3-4 = _v "6.3.4" "1130nycffid25rbnlgffsihhjiz75356iii0lmhkzrb8nlca8q7d"; # 2024-04-22
      v6-0-0 = _v "6.0.0" "08hy2fwr6rlqc0cf6g815fly45nmf1kv3ngfgmy4k2jyf5rd8z50"; # 2024-04-08
      v5-47-2 = _v "5.47.2" "0wax65hy9gc56gch0ypgm10a9qya5r6ygnnv3klna1a94nf32d4n"; # 2024-03-28
      v5-47-1 = _v "5.47.1" "171iwpniwc7q35vd5vgz9jzd8j24az4f3gsxgdlp1a4r5y5kxjm9"; # 2024-03-22
      v5-44-4 = _v "5.44.4" "124fms4hpqyr40a9jb5bvh48m5dvqi7m7xyq234c7d2jbqm0w201"; # 2024-03-18
      v5-43-7 = _v "5.43.7" "1n8mbv198kjx4drbvv6alh3l2vr86spvv3zik99ppajfpi8pv0rv"; # 2024-03-14
      v5-42-3 = _v "5.42.3" "0qkbivgpwbx7ffwh7szs725qhvla2bh1h66ja5zdnyry5wagcz8k"; # 2024-02-14
    };
    # this agent is useful for pushing k8s logs into loki
    agent =
      { cluster  # cluster name to report
      , lokiHost ? "loki-write.loki.svc.cluster.local:3100"  # default for a base install of the helm chart
      , name ? "grafana-agent"
      , namespace ? "default"
      , extraConfig ? { }  # extra prometheus config for agent.yaml, as an attrset
      , image ? "${image_base}:${image_tag}"
      , image_base ? "grafana/agent"
      , image_tag ? "v0.42.0"
      , scheme ? "http"
      , lokiPath ? "/loki/api/v1/push"
      , basicAuth ? false
      , basicAuthUser ? ""
      , basicAuthPassword ? ""
      }:
      let
        sa = {
          apiVersion = "v1";
          kind = "ServiceAccount";
          metadata = {
            inherit name namespace;
          };
        };
        cluster_role = {
          apiVersion = "rbac.authorization.k8s.io/v1";
          kind = "ClusterRole";
          metadata = {
            inherit name;
          };
          rules = [
            {
              apiGroups = [ "" ];
              resources = [
                "nodes"
                "nodes/proxy"
                "services"
                "endpoints"
                "pods"
                "events"
              ];
              verbs = [
                "get"
                "list"
                "watch"
              ];
            }
            {
              nonResourceURLs = [ "/metrics" ];
              verbs = [ "get" ];
            }
          ];
        };
        cluster_role_binding = {
          apiVersion = "rbac.authorization.k8s.io/v1";
          kind = "ClusterRoleBinding";
          metadata = { inherit name; };
          roleRef = {
            apiGroup = "rbac.authorization.k8s.io";
            kind = "ClusterRole";
            inherit name;
          };
          subjects = [
            {
              inherit name namespace;
              kind = "ServiceAccount";
            }
          ];
        };
        service = {
          apiVersion = "v1";
          kind = "Service";
          metadata = {
            labels = { inherit name; };
            inherit name namespace;
          };
          spec = {
            clusterIP = "None";
            ports = [
              {
                name = "grafana-agent-http-metrics";
                port = 80;
                targetPort = 80;
              }
            ];
            selector = {
              inherit name;
            };
          };
        };
        config = {
          apiVersion = "v1";
          data = {
            "agent.yaml" = toYAMLDoc
              ({
                integrations = {
                  eventhandler = {
                    cache_path = "/var/lib/agent/eventhandler.cache";
                    logs_instance = "integrations";
                  };
                };
                logs = {
                  configs = [
                    {
                      clients = [
                        {
                          ${if basicAuth then "basic_auth" else null} = {
                            password = basicAuthPassword;
                            username = basicAuthUser;
                          };
                          external_labels = {
                            inherit cluster;
                            job = "integrations/kubernetes/eventhandler";
                          };
                          url = "${scheme}://${lokiHost}${lokiPath}";
                        }
                      ];
                      name = "integrations";
                      positions = {
                        filename = "/tmp/positions.yaml";
                      };
                      target_config = {
                        sync_period = "10s";
                      };
                    }
                  ];
                };
              } // extraConfig);
          };
          kind = "ConfigMap";
          metadata = {
            inherit name namespace;
          };
        };
        statefulset = {
          apiVersion = "apps/v1";
          kind = "StatefulSet";
          metadata = {
            inherit name namespace;
          };
          spec = {
            replicas = 1;
            selector = {
              matchLabels = {
                inherit name;
              };
            };
            serviceName = name;
            template = {
              metadata = {
                labels = { inherit name; };
              };
              spec = {
                containers = [
                  {
                    inherit image;
                    args = [
                      "-config.expand-env=true"
                      "-config.file=/etc/agent/agent.yaml"
                      "-enable-features=integrations-next"
                      "-server.http.address=0.0.0.0:80"
                    ];
                    env = [
                      {
                        name = "HOSTNAME";
                        valueFrom = {
                          fieldRef = {
                            fieldPath = "spec.nodeName";
                          };
                        };
                      }
                    ];
                    imagePullPolicy = "IfNotPresent";
                    inherit name;
                    ports = [
                      {
                        containerPort = 80;
                        name = "http-metrics";
                      }
                    ];
                    volumeMounts = [
                      {
                        mountPath = "/var/lib/agent";
                        name = "agent-wal";
                      }
                      {
                        mountPath = "/etc/agent";
                        inherit name;
                      }
                    ];
                  }
                ];
                serviceAccountName = "grafana-agent";
                volumes = [
                  {
                    configMap = {
                      inherit name;
                    };
                    inherit name;
                  }
                ];
              };
            };
            updateStrategy = {
              type = "RollingUpdate";
            };
            volumeClaimTemplates = [
              {
                apiVersion = "v1";
                kind = "PersistentVolumeClaim";
                metadata = {
                  name = "agent-wal";
                  inherit namespace;
                };
                spec = {
                  accessModes = [
                    "ReadWriteOnce"
                  ];
                  resources = {
                    requests = {
                      storage = "5Gi";
                    };
                  };
                };
              }
            ];
          };
        };
      in
      assert basicAuth -> basicAuthUser != "";
      assert basicAuth -> basicAuthPassword != "";
      ''
        ${toYAMLDoc config}
        ${toYAMLDoc sa}
        ${toYAMLDoc cluster_role}
        ${toYAMLDoc cluster_role_binding}
        ${toYAMLDoc service}
        ${toYAMLDoc statefulset}
      '';

    # promtail will tail all the stderr and stdout of logs in the cluster to the specified loki endpoint
    promtail =
      { cluster  # cluster name to report
      , lokiHost ? "loki-write.loki.svc.cluster.local:3100"  # default for a base install of the helm chart
      , name ? "promtail"
      , namespace ? "default"
      , extraConfig ? { } # extra config for promtail.yml, as an attrset
      , scheme ? "http"
      , lokiPath ? "/loki/api/v1/push"
      , basicAuth ? false
      , basicAuthUser ? ""
      , basicAuthPassword ? ""
      }:
      let
        labels = { inherit name; };
        sa = {
          apiVersion = "v1";
          kind = "ServiceAccount";
          metadata = {
            inherit name namespace;
          };
        };
        clusterrolebinding = {
          apiVersion = "rbac.authorization.k8s.io/v1";
          kind = "ClusterRoleBinding";
          metadata = { inherit name; };
          roleRef = {
            apiGroup = "rbac.authorization.k8s.io";
            kind = "ClusterRole";
            inherit name;
          };
          subjects = [
            {
              kind = "ServiceAccount";
              inherit name namespace;
            }
          ];
        };
        clusterrole = {
          apiVersion = "rbac.authorization.k8s.io/v1";
          kind = "ClusterRole";
          metadata = { inherit name; };
          rules = [
            {
              apiGroups = [ "" ];
              resources = [
                "nodes"
                "services"
                "pods"
              ];
              verbs = [
                "get"
                "watch"
                "list"
              ];
            }
          ];
        };
        configmap = {
          apiVersion = "v1";
          data = {
            "promtail.yaml" = toYAML ({
              clients = [
                {
                  ${if basicAuth then "basic_auth" else null} = {
                    password = basicAuthPassword;
                    username = basicAuthUser;
                  };
                  url = "${scheme}://${lokiHost}${lokiPath}";
                }
              ];
              positions = {
                filename = "/tmp/positions.yaml";
              };
              scrape_configs = [
                {
                  job_name = "pod-logs";
                  kubernetes_sd_configs = [
                    {
                      role = "pod";
                    }
                  ];
                  pipeline_stages = [
                    {
                      docker = { };
                    }
                    {
                      static_labels = {
                        inherit cluster;
                      };
                    }
                  ];
                  relabel_configs = [
                    {
                      source_labels = [
                        "__meta_kubernetes_pod_node_name"
                      ];
                      target_label = "__host__";
                    }
                    {
                      action = "labelmap";
                      regex = "__meta_kubernetes_pod_label_(.+)";
                    }
                    {
                      action = "replace";
                      replacement = "$1";
                      separator = "/";
                      source_labels = [
                        "__meta_kubernetes_namespace"
                        "__meta_kubernetes_pod_name"
                      ];
                      target_label = "job";
                    }
                    {
                      action = "replace";
                      source_labels = [
                        "__meta_kubernetes_namespace"
                      ];
                      target_label = "namespace";
                    }
                    {
                      action = "replace";
                      source_labels = [
                        "__meta_kubernetes_pod_name"
                      ];
                      target_label = "pod";
                    }
                    {
                      action = "replace";
                      source_labels = [
                        "__meta_kubernetes_pod_container_name"
                      ];
                      target_label = "container";
                    }
                    {
                      replacement = "/var/log/pods/*$1/*.log";
                      separator = "/";
                      source_labels = [
                        "__meta_kubernetes_pod_uid"
                        "__meta_kubernetes_pod_container_name"
                      ];
                      target_label = "__path__";
                    }
                  ];
                }
              ];
              server = {
                grpc_listen_port = 0;
                http_listen_port = 9080;
              };
              target_config = {
                sync_period = "10s";
              };
            } // extraConfig);
          };
          kind = "ConfigMap";
          metadata = {
            inherit namespace;
            name = "promtail-config";
          };
        };
        daemonset = {
          apiVersion = "apps/v1";
          kind = "DaemonSet";
          metadata = { inherit name namespace; };
          spec = {
            selector = {
              matchLabels = labels;
            };
            template = {
              metadata = {
                inherit labels;
              };
              spec = {
                containers = [
                  {
                    args = [
                      "-config.file=/etc/promtail/promtail.yaml"
                    ];
                    env = [
                      {
                        name = "HOSTNAME";
                        valueFrom = {
                          fieldRef = {
                            fieldPath = "spec.nodeName";
                          };
                        };
                      }
                    ];
                    image = "grafana/promtail";
                    name = "promtail-container";
                    volumeMounts = [
                      {
                        mountPath = "/var/log";
                        name = "logs";
                      }
                      {
                        mountPath = "/etc/promtail";
                        name = "promtail-config";
                      }
                      {
                        mountPath = "/var/lib/docker/containers";
                        name = "varlibdockercontainers";
                        readOnly = true;
                      }
                    ];
                  }
                ];
                serviceAccount = "promtail";
                volumes = [
                  {
                    hostPath = {
                      path = "/var/log";
                    };
                    name = "logs";
                  }
                  {
                    hostPath = {
                      path = "/var/lib/docker/containers";
                    };
                    name = "varlibdockercontainers";
                  }
                  {
                    configMap = {
                      name = "promtail-config";
                    };
                    name = "promtail-config";
                  }
                ];
              };
            };
          };
        };
      in
      assert basicAuth -> basicAuthUser != "";
      assert basicAuth -> basicAuthPassword != "";
      ''
        ${toYAMLDoc sa}
        ${toYAMLDoc clusterrole}
        ${toYAMLDoc clusterrolebinding}
        ${toYAMLDoc configmap}
        ${toYAMLDoc daemonset}
      '';
  };
  mimir = rec {
    defaults = {
      name = "mimir";
      chart_name = "mimir-distributed";
      namespace = "mimir";
    };
    chart = hex.k8s._.chart {
      inherit defaults;
      chart_url = version: _chart_url { inherit version; inherit (defaults) name; };
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v5-3-0;
      v5-3-0 = _v "5.3.0" "1amv2qmpidsk6gl40pf7rfckmhvxqjzl7rc97b8p7h75wmwglhj4"; # 2024-04-10
      v5-2-3 = _v "5.2.3" "0d8snrg661fwm2p621h0wf8l8aygyc492xkdc5yxl89i33d29nbx"; # 2024-03-15
      v5-1-2 = _v "5.1.2" "0frz4fs0za92flb81cgpxhjrkrsmypykz6ynn5j4z1vafqs4ckhq";
    };
  };
  oncall = rec {
    defaults = {
      name = "oncall";
      chart_name = "oncall";
      namespace = "oncall";
    };
    chart = hex.k8s._.chart {
      inherit defaults;
      chart_url = version: _chart_url { inherit version; inherit (defaults) name; };
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v1-9-22;
      v1-9-22 = _v "1.9.22" "01r59filgn5zygpp96lw036w6kl295xvyiz8j09pmdwca5vgk5ya"; # 2024-09-04
      v1-9-18 = _v "1.9.18" "0kdjr3h8kc6hvjb74n9ywklgd59jj3i1zxd60xp8hhrc13sab9am"; # 2024-08-29
      v1-8-13 = _v "1.8.13" "1jnvq2zyi4ncqw6l8i4cg1ixqhq16zwzbwbxfy9dqb0ml8ypssz9"; # 2024-08-15
      v1-7-2 = _v "1.7.2" "0xi4i4a0fklri71z2pia0ypj48nxw9nhvh7849yprjjmws35lrr6"; # 2024-06-20
      v1-7-1 = _v "1.7.1" "0fxklg48bvifbfss1xsahybzdz05hapyq2c2rfz91l8nxkrcqs3j"; # 2024-06-13
      v1-6-2 = _v "1.6.2" "1dzvv6wxrzxgv7ff25g1p5k2j3f3i1h4kvb35iwf8gw1lk4y3v12"; # 2024-06-05
      v1-5-5 = _v "1.5.5" "1jv6d8h7px45f0dab9ws92f4vjnyqq1b10k657rliks1kv93nqxs"; # 2024-06-03
      v1-4-7 = _v "1.4.7" "0a8ij66rcps0p3z8p69nl1y5742fh5a19slqfzl28kpzdikmx629"; # 2024-05-13
      v1-3-118 = _v "1.3.118" "0ywz3v2q9iy5z24rad3m9570hc3jwsfr1yzj0ba3m8fq4zyvb7k6"; # 2024-04-11
      v1-3-113 = _v "1.3.113" "0yqlsfhmcabppcczad6hdlaav2nxi9z9i4nn51h1rdh6w7g6xc2s"; # 2024-03-21
      v1-3-45 = _v "1.3.45" "1xrrryq5bvvbpxplpnwqn6yr0c1sp4k2idib5hybky8sczyfjjyn";
    };
  };
in
{ inherit loki mimir oncall; }
