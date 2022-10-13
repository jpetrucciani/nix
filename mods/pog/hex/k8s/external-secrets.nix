{ hex, pkgs }:
let
  inherit (hex) attrIf ifNotEmptyAttr toYAML;

  external-secrets = rec {
    defaults = {
      name = "external-secrets";
      namespace = "external-secrets";
      version = "0.6.0";
      sha256 = "0pf6z5yzr32cj0i9s1wg0vmbjqrbcsc11gz4s6ymh5jcx07x2b6p";
      store_name = "gsm";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      v0-5-9 = _v "0.5.9" "0mxm237a7q8gvxvpcqk6zs0rbv725260xdvhd27kibirfjwm4zxl";
      v0-6-0 = _v defaults.version defaults.sha256;
      latest = v0-6-0;
    };
    chart_url = version: hex.k8s.helm.charts.url.github {
      inherit version;
      org = "external-secrets";
      repo = "external-secrets";
      repoName = "helm-chart";
      chartName = "external-secrets";
    };
    chart =
      { name ? defaults.name
      , namespace ? defaults.namespace
      , values ? [ ]
      , sets ? [ "installCRDs=true" ]
      , version ? defaults.version
      , sha256 ? defaults.sha256
      , extraFlags ? [ hex.k8s.helm.constants.flags.create-namespace ]
      }: hex.k8s.helm.build {
        inherit name namespace values sets version sha256 extraFlags;
        url = chart_url version;
      };
    cluster_store = rec {
      build =
        { gcp_project
        , name ? defaults.store_name
        , secret ? "${name}-creds"
        , filename ? "${name}-creds.json"
        , namespace ? "external-secrets"
        }: ''
          ---
          ${toYAML (store {inherit name gcp_project secret filename namespace;})}
        '';
      store =
        { name
        , gcp_project
        , secret
        , filename
        , namespace
        }:
        {
          apiVersion = "external-secrets.io/v1beta1";
          kind = "ClusterSecretStore";
          metadata = {
            inherit name namespace;
            annotations = { } // hex.annotations;
          };
          spec = {
            provider = {
              gcpsm = {
                projectID = gcp_project;
                auth = {
                  secretRef = {
                    secretAccessKeySecretRef = {
                      inherit namespace;
                      name = secret;
                      key = filename;
                    };
                  };
                };
              };
            };
          };
        };
    };
    external_secret = rec {
      build =
        { name
        , filename
        , env ? ""
        , store ? defaults.store_name
        , store_kind ? "ClusterSecretStore"
        , refresh_interval ? "30m"
        , secret_ref ? ""
        , namespace ? "default"
        , extract ? false
        , extra_data ? [ ]
        , labels ? { }
        , string_data ? { }
        }: ''
          ---
          ${toYAML (secret {inherit name filename env store store_kind refresh_interval secret_ref namespace extract extra_data labels string_data;})}
        '';

      secret =
        { name
        , filename
        , env
        , store
        , store_kind
        , refresh_interval
        , secret_ref
        , namespace
        , extract
        , extra_data
        , labels
        , string_data
        }:
        let
          all_labels = labels // { HEX = "true"; };
        in
        {
          apiVersion = "external-secrets.io/v1beta1";
          kind = "ExternalSecret";
          metadata = {
            inherit name namespace;
            annotations = { } // hex.annotations;
          };
          spec = {
            refreshInterval = refresh_interval;
            secretStoreRef = {
              kind = store_kind;
              name = store;
            };
            target = {
              inherit name;
              creationPolicy = "Owner";
              deletionPolicy = "Retain";
              template = {
                ${ifNotEmptyAttr string_data "data"} = string_data;
                metadata = {
                  labels = all_labels;
                };
              };
            };
            ${attrIf extract "dataFrom"} = [
              {
                extract.key = if secret_ref == "" then "${env}${name}" else secret_ref;
              }
            ];
            ${attrIf (!extract) "data"} = [
              {
                secretKey = filename;
                remoteRef = {
                  key = if secret_ref == "" then "${env}${name}" else secret_ref;
                };
              }
            ] ++ extra_data;
          };
        };
    };
  };
in
external-secrets
