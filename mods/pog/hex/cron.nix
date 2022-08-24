{ hex }:
let
  inherit (hex) attrIf attrIfNotNull toYAML;

  cron = rec {
    build =
      { name
      , image ? "curlimages/curl:7.84.0"
      , schedule ? "0 * * * *"  # hourly at :00
      , labels ? [ ]
      , namespace ? "default"
      , failedJobsHistoryLimit ? 3
      , successfulJobsHistoryLimit ? 3
      , cpuRequest ? "100m"
      , cpuLimit ? null
      , memoryRequest ? "100Mi"
      , memoryLimit ? null
      , env ? { }
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
                        env = { HEX = true; } // env;
                        ${attrIfNotNull command "command"} = [ command ];
                        ${attrIfNotNull args "args"} = args;
                        resources = {
                          ${if (memoryLimit != null || cpuLimit != null) then "limits" else null} = {
                            ${attrIfNotNull memoryLimit "memory"} = memoryLimit;
                            ${attrIfNotNull cpuLimit "cpu"} = cpuLimit;
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
