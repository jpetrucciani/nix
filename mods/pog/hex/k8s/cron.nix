{ hex, ... }:
let
  inherit (hex) ifNotNull ifNotEmptyList toYAML;

  cron = {
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
      ''
        ---
        ${toYAML cron}
      '';
  };
in
cron
