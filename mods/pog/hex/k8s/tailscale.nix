# This module contains useful shorthands for using [tailscale](https://tailscale.com/) within kubernetes
{ hex, ... }:
let
  inherit (hex) toYAMLDoc boolToString concatMapStrings removePrefix ifNotNull ifNotEmptyList;

  imagePullPolicy = "Always";
  joinTags = concatMapStrings (x: ",tag:${x}");
  exitNode = "--advertise-exit-node";

  proxies = rec {
    defaults = {
      tailscale_resources = {
        cpu = "256m";
        memory = "512Mi";
      };
      cloudsql_resources = {
        cpu = "1";
        memory = "2Gi";
      };
      tailscale_image_base = "ghcr.io/tailscale/tailscale";
      tailscale_image_tag = "v1.60.1";
      cloudsql_image_base = "gcr.io/cloudsql-docker/gce-proxy";
      cloudsql_image_tag = "1.34.0";

      tags = [ "k8s" "proxy" ];
      cidr = "100.64.0.0/10";
    };
    sa = { name, namespace ? "default", extraConfig ? { } }: {
      apiVersion = "v1";
      kind = "ServiceAccount";
      metadata = {
        inherit name namespace;
        annotations = { } // hex.annotations;
      };
    } // extraConfig;
    secret = { name, namespace ? "default", extraConfig ? { } }: {
      apiVersion = "v1";
      kind = "Secret";
      metadata = {
        inherit name namespace;
        annotations = { } // hex.annotations;
      };
      stringData = {
        nop = "nop";
      };
    } // extraConfig;
    role = { name, namespace ? "default", extraConfig ? { } }: {
      apiVersion = "rbac.authorization.k8s.io/v1";
      kind = "Role";
      metadata = {
        inherit name namespace;
        annotations = { } // hex.annotations;
      };
      rules = [
        {
          apiGroups = [ "" ];
          resources = [ "secrets" ];
          verbs = [ "create" ];
        }
        {
          apiGroups = [ "" ];
          resources = [ "secrets" ];
          resourceNames = [ name ];
          verbs = [ "get" "update" "patch" ];
        }
      ];
    } // extraConfig;
    role-binding = { name, namespace ? "default", extraConfig ? { } }: {
      apiVersion = "rbac.authorization.k8s.io/v1";
      kind = "RoleBinding";
      metadata = {
        inherit name namespace;
        annotations = { } // hex.annotations;
      };
      subjects = [
        {
          inherit name;
          kind = "ServiceAccount";
        }
      ];
      roleRef = {
        inherit name;
        kind = "Role";
        apiGroup = "rbac.authorization.k8s.io";
      };
    } // extraConfig;
    network-policy = { name, namespace ? "default", cidr ? defaults.cidr, extraConfig ? { } }: {
      apiVersion = "networking.k8s.io/v1";
      kind = "NetworkPolicy";
      metadata = {
        inherit name namespace;
        annotations = { } // hex.annotations;
      };
      spec = {
        egress = [{ to = [{ ipBlock = { cidr = "0.0.0.0/0"; }; }]; }];
        ingress = [{ from = [{ ipBlock = { inherit cidr; }; }]; }];
        podSelector.matchLabels.app = name;
        policyTypes = [
          "Ingress"
          "Egress"
        ];
      };
    } // extraConfig;

    proxy = rec {
      build =
        { name
        , namespace ? "default"
        , destination_ip ? null
        , cidr ? defaults.cidr
        , tailscale_image ? "${tailscale_image_base}:${tailscale_image_tag}"
        , tailscale_image_base ? defaults.tailscale_image_base
        , tailscale_image_tag ? defaults.tailscale_image_tag
        , tags ? [ ]
        , default_tags ? defaults.tags
        , all_tags ? tags ++ default_tags
        , cpu ? defaults.tailscale_resources.cpu
        , memory ? defaults.tailscale_resources.memory
        , userspace ? false
        , exit_node ? false
        , subnet_router_cidr ? null
        , bind_local ? false
        , hostAliases ? [ ]
        }: ''
          ${toYAMLDoc (sa {inherit name namespace;})}
          ${toYAMLDoc (secret {inherit name namespace;})}
          ${toYAMLDoc (role {inherit name namespace;})}
          ${toYAMLDoc (role-binding {inherit name namespace;})}
          ${toYAMLDoc (network-policy {inherit name namespace cidr;})}
          ${toYAMLDoc (deployment {inherit name namespace destination_ip tailscale_image all_tags cpu memory userspace exit_node subnet_router_cidr bind_local hostAliases;})}
        '';
      deployment =
        { name
        , namespace
        , destination_ip
        , tailscale_image
        , all_tags
        , cpu
        , memory
        , userspace
        , exit_node
        , subnet_router_cidr
        , bind_local
        , hostAliases
        }:
        let
          exit_node_flag = if exit_node then " ${exitNode}" else "";
          _tags = removePrefix "," (joinTags all_tags);
          advertise_tags_flag = if builtins.length all_tags != 0 then "--advertise-tags=${_tags}" else "";
        in
        {
          apiVersion = "apps/v1";
          kind = "Deployment";
          metadata = {
            inherit name namespace;
            annotations = { } // hex.annotations;
          };
          spec = {
            selector.matchLabels.app = name;
            template = {
              metadata.labels.app = name;
              spec = {
                serviceAccountName = name;
                initContainers = [
                  {
                    name = "sysctler";
                    image = "busybox";
                    securityContext.privileged = true;
                    command = [ "/bin/sh" ];
                    args = [
                      "-c"
                      "sysctl -w net.ipv4.ip_forward=1 net.ipv6.conf.all.forwarding=1"
                    ];
                    resources = {
                      requests = {
                        cpu = "1m";
                        memory = "1Mi";
                      };
                    };
                  }
                ];
                containers = [
                  {
                    inherit imagePullPolicy;
                    name = "tailscale";
                    image = tailscale_image;
                    env = with hex.defaults.env; [
                      pod_ip
                      pod_name
                    ] ++ (hex.envAttrToNVP {
                      TS_KUBE_SECRET = name;
                      TS_USERSPACE = boolToString userspace;
                      TS_EXTRA_ARGS = "${advertise_tags_flag}${exit_node_flag}";
                      ${ifNotNull destination_ip "TS_DEST_IP"} = destination_ip;
                      ${ifNotNull subnet_router_cidr "TS_ROUTES"} = subnet_router_cidr;
                    });
                    resources = {
                      requests = {
                        inherit cpu memory;
                      };
                    };
                    securityContext.capabilities.add = [ "NET_ADMIN" ];
                    ${if bind_local then "lifecycle" else null}.postStart.exec.command = [
                      "/bin/sh"
                      "-c"
                      (builtins.concatStringsSep " && " [
                        "until tailscale --socket=/tmp/tailscaled.sock ping $TS_DEST_IP; do sleep 1; done"
                        "iptables -t nat -A PREROUTING -d $POD_IP -j DNAT --to-destination $TS_DEST_IP"
                        "iptables -t nat -A POSTROUTING -j MASQUERADE"
                      ]
                      )
                    ];
                  }
                ];
                ${ifNotEmptyList hostAliases "hostAliases"} = hostAliases;
              };
            };
          };
        };
    };

    cloudsql-proxy = rec {
      build =
        { name
        , gcp_project
        , cloudsql_instance
        , namespace ? "default"
        , gcp_region ? "us-west1"
        , cidr ? defaults.cidr
        , tailscale_image ? "${tailscale_image_base}:${tailscale_image_tag}"
        , tailscale_image_base ? defaults.tailscale_image_base
        , tailscale_image_tag ? defaults.tailscale_image_tag
        , cloudsql_image ? "${cloudsql_image_base}:${cloudsql_image_tag}"
        , cloudsql_image_base ? defaults.cloudsql_image_base
        , cloudsql_image_tag ? defaults.cloudsql_image_tag
        , cpu ? defaults.cloudsql_resources.cpu
        , memory ? defaults.cloudsql_resources.memory
        , secret_name ? "cloud-sql-creds"
        , port ? 5432  # postgres default?
        , tags ? [ ]
        , default_tags ? defaults.tags
        , all_tags ? tags ++ default_tags
        , tailscale_cpu ? defaults.tailscale_resources.cpu
        , tailscale_memory ? defaults.tailscale_resources.memory
        , userspace ? false
        , exit_node ? false
        , hostAliases ? [ ]
        }: ''
          ${toYAMLDoc (sa {inherit name namespace;})}
          ${toYAMLDoc (secret {inherit name namespace;})}
          ${toYAMLDoc (role {inherit name namespace;})}
          ${toYAMLDoc (role-binding {inherit name namespace;})}
          ${toYAMLDoc (network-policy {inherit name namespace cidr;})}
          ${toYAMLDoc (deployment {inherit name namespace tailscale_image cloudsql_image memory cpu gcp_project gcp_region cloudsql_instance secret_name port all_tags tailscale_cpu tailscale_memory userspace exit_node hostAliases;})}
        '';
      deployment =
        { name
        , namespace
        , tailscale_image
        , cloudsql_image
        , memory
        , cpu
        , gcp_project
        , gcp_region
        , cloudsql_instance
        , secret_name
        , port
        , all_tags
        , tailscale_cpu
        , tailscale_memory
        , userspace
        , exit_node
        , hostAliases
        }:
        let
          exit_node_flag = if exit_node then " ${exitNode}" else "";
          _tags = removePrefix "," (joinTags all_tags);
          advertise_tags_flag = if builtins.length all_tags != 0 then "--advertise-tags=${_tags}" else "";
        in
        {
          apiVersion = "apps/v1";
          kind = "Deployment";
          metadata = {
            inherit name namespace;
            annotations = { } // hex.annotations;
          };
          spec = {
            selector.matchLabels.app = name;
            template = {
              metadata.labels.app = name;
              spec = {
                serviceAccountName = name;
                volumes = [
                  {
                    name = "creds";
                    secret.secretName = secret_name;
                  }
                ];
                containers = [
                  {
                    inherit imagePullPolicy;
                    name = "proxy";
                    image = cloudsql_image;
                    command = [
                      "/cloud_sql_proxy"
                      "-instances=${gcp_project}:${gcp_region}:${cloudsql_instance}=tcp:0.0.0.0:${toString port}"
                      "-credential_file=/secrets/service_account.json"
                    ];
                    resources.requests = {
                      inherit cpu memory;
                    };
                    securityContext.runAsNonRoot = true;
                    volumeMounts = [
                      {
                        name = "creds";
                        mountPath = "/secrets/";
                        readOnly = true;
                      }
                    ];
                  }
                  {
                    inherit imagePullPolicy;
                    name = "tailscale";
                    image = tailscale_image;
                    env = with hex.defaults.env; [
                      pod_ip
                      pod_name
                    ] ++ (hex.envAttrToNVP {
                      TS_KUBE_SECRET = name;
                      TS_USERSPACE = boolToString userspace;
                      TS_EXTRA_ARGS = "${advertise_tags_flag}${exit_node_flag}";
                    });
                    resources = {
                      requests = {
                        cpu = tailscale_cpu;
                        memory = tailscale_memory;
                      };
                    };
                    securityContext.capabilities.add = [ "NET_ADMIN" ];
                  }
                ];
                ${ifNotEmptyList hostAliases "hostAliases"} = hostAliases;
              };
            };
          };
        };
    };
  };
in
proxies
