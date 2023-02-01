{ hex, ... }:
let
  devtron = rec {
    defaults = {
      name = "devtron";
      namespace = "devtron";
      version = "0.22.49";
      sha256 = "116kmaspbilzyhrzgla70qpwvbd0znvgsn2xgnvwb4qz9wjf3qq5";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      latest = v0-22-49;
      v0-22-49 = _v defaults.version defaults.sha256;
      v0-22-48 = _v "0.22.48" "1xfh9gzjsk7p7gndf4p2v856bb8a0105sli1nndsll19xy2mnhil";

    };
    chart_url = version: "https://github.com/devtron-labs/charts/releases/download/devtron-operator-${version}/devtron-operator-${version}.tgz";
    chart =
      { name ? defaults.name
      , namespace ? defaults.namespace
      , values ? [ ]
      , sets ? [ ]
      , version ? defaults.version
      , sha256 ? defaults.sha256
      , forceNamespace ? true
      , extraFlags ? [ hex.k8s.helm.constants.flags.create-namespace ]
      , sortYaml ? false
      , preRender ? ""
      , postRender ? ""
      }: hex.k8s.helm.build {
        inherit name namespace values sets version sha256 extraFlags forceNamespace sortYaml postRender;
        url = chart_url version;
        preRender = helpers: ''
          ${preRender}
          substituteInPlace \
            ./templates/app-sync-job.yaml \
            --replace '.Capabilities.APIVersions.Has "batch/v1/Job"' 'true'
          substituteInPlace \
            ./templates/app-sync-job.yaml \
            --replace '.Capabilities.APIVersions.Has "batch/v1/CronJob"' 'true'
          substituteInPlace \
            ./templates/migrator.yaml \
            --replace '$.Capabilities.APIVersions.Has "batch/v1/Job"' 'true'
        '';
      };
  };
in
devtron
