_:
let
  server = rec {
    build = args: ''
      ---
      ${deployment args}
      ---
      ${service args}
      ---
      ${pvc args}
    '';
    deployment =
      { name ? "woodpecker"
      , namespace ? "default"
      , image ? "${image_base}:${image_tag}"
      , image_base ? "woodpeckerci/woodpecker-server"
      , image_tag ? "v0.15"
      , labels ? { }
      , default_labels ? { app = "woodpecker"; }
      , all_labels ? labels // default_labels
      , admins ? "jpetrucciani"
      , host ? ""
        # , github ? true
      , github_client ? ""
      , github_secret ? ""
      , agent_secret ? "this_is_a_secret"
      , ...
      }: {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          inherit name namespace;
          labels = all_labels;
        };
        spec = {
          replicas = 1;
          selector = {
            matchLabels = all_labels;
          };
          template = {
            metadata = {
              annotations = {
                "prometheus.io/scrape" = "true";
              };
              labels = all_labels;
            };
            spec = {
              containers = [
                {
                  env = [
                    {
                      name = "WOODPECKER_ADMIN";
                      value = admins;
                    }
                    {
                      name = "WOODPECKER_HOST";
                      value = host;
                    }
                    {
                      name = "WOODPECKER_GITHUB";
                      value = "true";
                    }
                    {
                      name = "WOODPECKER_GITHUB_CLIENT";
                      value = github_client;
                    }
                    {
                      name = "WOODPECKER_GITHUB_SECRET";
                      value = github_secret;
                    }
                    {
                      name = "WOODPECKER_AGENT_SECRET";
                      value = agent_secret;
                    }
                  ];
                  inherit image name;
                  imagePullPolicy = "Always";
                  volumeMounts = [
                    {
                      mountPath = "/var/lib/woodpecker";
                      name = "sqlite-volume";
                    }
                  ];
                }
              ];
              volumes = [
                {
                  name = "sqlite-volume";
                  persistentVolumeClaim = {
                    claimName = "woodpecker-pvc";
                  };
                }
              ];
            };
          };
        };
      };
    service =
      { name
      , namespace ? "default"
      , labels ? { }
      , default_labels ? { app = "woodpecker"; }
      , all_labels ? labels // default_labels
      , port ? 8000
      , grpc_port ? 9000
      , ...
      }: {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          inherit name namespace;
        };
        spec = {
          ports = [
            {
              inherit port;
              name = "http";
              protocol = "TCP";
              targetPort = port;
            }
            {
              name = "grpc";
              port = grpc_port;
              protocol = "TCP";
              targetPort = grpc_port;
            }
          ];
          selector = all_labels;
          type = "ClusterIP";
        };
      };
    pvc = { name, namespace ? "default", storage ? "10Gi", ... }: {
      apiVersion = "v1";
      kind = "PersistentVolumeClaim";
      metadata = {
        inherit name namespace;
      };
      spec = {
        accessModes = [
          "ReadWriteOnce"
        ];
        resources = {
          requests = {
            inherit storage;
          };
        };
        storageClassName = "local-path";
      };
    };
  };
  agent = rec {
    build = args: ''
      ---
      ${deployment args}
    '';
    deployment =
      { name ? "woodpecker-agent"
      , namespace ? "default"
      , image ? "${image_base}:${image_tag}"
      , image_base ? "woodpeckerci/woodpecker-agent"
      , image_tag ? "v0.15"
      , labels ? { }
      , default_labels ? { app = "woodpecker-agent"; }
      , all_labels ? labels // default_labels
      , replicas ? 3
      , grpc_port ? 9000
      , agent_secret ? "this_is_a_secret"
      , cpu ? 2
      , memory ? "2Gi"
      , dind_image ? "${dind_base}:${dind_tag}"
      , dind_base ? "docker"
      , dind_tag ? "19.03.5-dind"
      }: {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = {
          inherit name namespace;
          labels = all_labels;
        };
        spec = {
          inherit replicas;
          selector = {
            matchLabels = all_labels;
          };
          template = {
            metadata = {
              annotations = null;
              labels = all_labels;
            };
            spec = {
              containers = [
                {
                  env = [
                    {
                      name = "WOODPECKER_SERVER";
                      value = "woodpecker.${namespace}.svc.cluster.local:${grpc_port}";
                    }
                    {
                      name = "WOODPECKER_AGENT_SECRET";
                      value = agent_secret;
                    }
                  ];
                  inherit image;
                  imagePullPolicy = "Always";
                  name = "agent";
                  ports = [
                    {
                      containerPort = 3000;
                      name = "http";
                      protocol = "TCP";
                    }
                  ];
                  resources = {
                    limits = {
                      inherit cpu memory;
                    };
                  };
                  volumeMounts = [
                    {
                      name = "sock-dir";
                      path = "/var/run";
                    }
                  ];
                }
                {
                  env = [
                    {
                      name = "DOCKER_DRIVER";
                      value = "overlay2";
                    }
                  ];
                  image = dind_image;
                  name = "dind";
                  resources = {
                    limits = {
                      cpu = 1;
                      memory = "2Gi";
                    };
                  };
                  securityContext = {
                    privileged = true;
                  };
                  volumeMounts = [
                    {
                      mountPath = "/var/run";
                      name = "sock-dir";
                    }
                  ];
                }
              ];
              volumes = [
                {
                  emptyDir = { };
                  name = "sock-dir";
                }
              ];
            };
          };
        };
      };
  };
in
{ inherit agent server; }
