{ hex, ... }:
let
  inherit (hex) ifNotNull ifNotEmptyList toYAML;

  cron = {
    build =
      { name
      , image ? "curlimages/curl:7.85.0"
      , schedule ? "0 * * * *"  # hourly at :00
      , labels ? [ ]
      , namespace ? "default"
      , failedJobsHistoryLimit ? 3
      , successfulJobsHistoryLimit ? 3
      , cpuRequest ? "100m"
      , cpuLimit ? null
      , memoryRequest ? "100Mi"
      , memoryLimit ? null
      , env ? [ ]
      , command ? null
      , args ? null
      , restartPolicy ? "Never"
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
                    inherit restartPolicy;
                    containers = [
                      {
                        inherit name image;
                        env = [{ name = "HEX"; value = "true"; }] ++ env;
                        ${ifNotNull command "command"} = [ command ];
                        ${ifNotNull args "args"} = args;
                        resources = {
                          ${if (memoryLimit != null || cpuLimit != null) then "limits" else null} = {
                            ${ifNotNull memoryLimit "memory"} = memoryLimit;
                            ${ifNotNull cpuLimit "cpu"} = cpuLimit;
                          };
                          requests = {
                            cpu = cpuRequest;
                            memory = memoryRequest;
                          };
                        };
                      }
                    ];
                  };
                };
              };
            };
          };
        };
      in
      ''
        ---
        ${toYAML cron}
      '';
  };
in
cron
