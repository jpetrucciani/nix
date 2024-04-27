# This hex spell allows concise cron job declaration in Kubernetes.
{ hex, ... }:
let
  inherit (hex) ifNotNull ifNotEmptyList toYAMLDoc;

  cron = {
    enum = {
      restart_policy = {
        never = "Never";
        on_failure = "OnFailure";
        always = "Always";
      };
    };
    build =
      { name
      , image ? "curlimages/curl:8.5.0"
      , schedule ? "0 * * * *"  # hourly at :00
      , labels ? [ ]
      , namespace ? "default"
      , failedJobsHistoryLimit ? 3
      , successfulJobsHistoryLimit ? 3
      , cpuRequest ? "100m"
      , cpuLimit ? null
      , memoryRequest ? "100Mi"
      , memoryLimit ? null
      , ephemeralStorageRequest ? null
      , ephemeralStorageLimit ? null
      , env ? [ ]
      , envAttrs ? { }
      , envFrom ? [ ]
      , sa ? "default"
      , command ? null
      , args ? null
      , restartPolicy ? "Never"
      , extra ? { } # extra escape hatch to use any other options!
      }:
      let
        cron = {
          apiVersion = "batch/v1";
          kind = "CronJob";
          metadata = {
            inherit name namespace;
            annotations = { } // hex.annotations;
            ${ifNotEmptyList labels "labels"} = labels;
          };
          spec = {
            inherit failedJobsHistoryLimit successfulJobsHistoryLimit schedule;
            jobTemplate = {
              spec = {
                template = {
                  spec = {
                    serviceAccountName = sa;
                    inherit restartPolicy;
                    containers = [
                      {
                        inherit name image;
                        env = with hex.defaults.env; [
                          pod_ip
                          pod_name
                        ] ++ [{ name = "HEX"; value = "true"; }] ++ env ++ (hex.envAttrToNVP envAttrs);
                        ${ifNotEmptyList envFrom "envFrom"} = envFrom;
                        ${ifNotNull command "command"} = if builtins.isString command then [ command ] else command;
                        ${ifNotNull args "args"} = args;
                        resources = {
                          ${if (memoryLimit != null || cpuLimit != null || ephemeralStorageLimit != null) then "limits" else null} = {
                            ${ifNotNull memoryLimit "memory"} = memoryLimit;
                            ${ifNotNull cpuLimit "cpu"} = cpuLimit;
                            ${ifNotNull ephemeralStorageLimit "ephemeral-storage"} = ephemeralStorageLimit;
                          };
                          ${if (memoryRequest != null || cpuRequest != null || ephemeralStorageRequest != null) then "requests" else null} = {
                            ${ifNotNull cpuRequest "cpu"} = cpuRequest;
                            ${ifNotNull memoryRequest "memory"} = memoryRequest;
                            ${ifNotNull ephemeralStorageRequest "ephemeral-storage"} = ephemeralStorageRequest;
                          };
                        };
                      }
                    ];
                  };
                };
              };
            };
          };
        } // extra;
      in
      toYAMLDoc cron;

    kube_cron = {
      build =
        { name
        , image ? "ghcr.io/jpetrucciani/k8s-aws:latest"
        , schedule ? "0 * * * *"  # hourly at :00
        , labels ? [ ]
        , namespace ? "default"
        , failedJobsHistoryLimit ? 3
        , successfulJobsHistoryLimit ? 3
        , cpuRequest ? "100m"
        , cpuLimit ? null
        , memoryRequest ? "100Mi"
        , memoryLimit ? null
        , ephemeralStorageRequest ? null
        , ephemeralStorageLimit ? null
        , roleRules ? [
            {
              apiGroups = [ "" ];
              resources = [ "pods" ];
              verbs = [ "delete" "get" "list" ];
            }
          ]
        , env ? [ ]
        , envAttrs ? { }
        , envFrom ? [ ]
        , command ? "bash"
        , args ? [ "-c" ''kubectl get pods'' ]
        , restartPolicy ? "OnFailure"
        , extraCron ? { } # extra escape hatch to use any other options!
        , extraCronContainer ? { } # extra escape hatch to use any other options!
        }:
        let
          sa_name = "${name}-sa";
          role_name = "${name}-role";
          sa = {
            apiVersion = "v1";
            kind = "ServiceAccount";
            metadata = {
              inherit namespace;
              name = sa_name;
            };
          };
          role = {
            apiVersion = "rbac.authorization.k8s.io/v1";
            kind = "Role";
            metadata = {
              inherit namespace;
              name = role_name;
            };
            rules = roleRules;
          };
          role_binding = {
            apiVersion = "rbac.authorization.k8s.io/v1";
            kind = "RoleBinding";
            metadata = {
              inherit namespace;
              name = "${name}-rb";
            };
            roleRef = {
              apiGroup = "rbac.authorization.k8s.io";
              kind = "Role";
              name = role_name;
            };
            subjects = [
              {
                kind = "ServiceAccount";
                name = sa_name;
              }
            ];
          };
          cron = {
            apiVersion = "batch/v1";
            kind = "CronJob";
            metadata = {
              inherit name namespace;
              ${ifNotEmptyList labels "labels"} = labels;
            };
            spec = {
              inherit failedJobsHistoryLimit successfulJobsHistoryLimit schedule;
              jobTemplate = {
                spec = {
                  template = {
                    spec = {
                      containers = [
                        ({
                          inherit image name;
                          env = with hex.defaults.env; [
                            pod_ip
                            pod_name
                          ] ++ [{ name = "HEX"; value = "true"; }] ++ env ++ (hex.envAttrToNVP envAttrs);
                          ${ifNotEmptyList envFrom "envFrom"} = envFrom;
                          ${ifNotNull command "command"} = if builtins.isString command then [ command ] else command;
                          ${ifNotNull args "args"} = args;
                          resources = {
                            ${if (memoryLimit != null || cpuLimit != null || ephemeralStorageLimit != null) then "limits" else null} = {
                              ${ifNotNull memoryLimit "memory"} = memoryLimit;
                              ${ifNotNull cpuLimit "cpu"} = cpuLimit;
                              ${ifNotNull ephemeralStorageLimit "ephemeral-storage"} = ephemeralStorageLimit;
                            };
                            ${if (memoryRequest != null || cpuRequest != null || ephemeralStorageRequest != null) then "requests" else null} = {
                              ${ifNotNull cpuRequest "cpu"} = cpuRequest;
                              ${ifNotNull memoryRequest "memory"} = memoryRequest;
                              ${ifNotNull ephemeralStorageRequest "ephemeral-storage"} = ephemeralStorageRequest;
                            };
                          };
                        } // extraCronContainer)
                      ];
                      inherit restartPolicy;
                      serviceAccountName = sa_name;
                    };
                  };
                };
              };
            };
          } // extraCron;
        in
        ''
          ${toYAMLDoc sa}
          ${toYAMLDoc role}
          ${toYAMLDoc role_binding}
          ${toYAMLDoc cron}
        '';
    };
  };
in
cron
