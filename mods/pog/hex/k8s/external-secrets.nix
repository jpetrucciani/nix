{ hex, ... }:
let
  inherit (hex) attrIf ifNotEmptyAttr toYAML;

  external-secrets = rec {
    defaults = {
      name = "external-secrets";
      namespace = "external-secrets";
      version = "0.8.3";
      sha256 = "16rqxlql8ywc99xikh1l1cxm2b8cdi2ak3ydss0i0f6wadyhjmic";
      store_name = "gsm";
    };
    version = rec {
      _v = v: s: args: chart (args // { version = v; sha256 = s; });
      latest = v0-8-3;
      v0-8-3 = _v defaults.version defaults.sha256;
      v0-7-2 = _v "0.7.2" "17isdcbb94kqwxg0v0mfj1ypjiqn3airghnd1bswlg609w73a8h4";
      v0-6-1 = _v "0.6.1" "02kacs4wdp5q9dlpndkzj4fxi30kpl6gxfqalgq5q9y3vr3l5gwv";
      v0-5-9 = _v "0.5.9" "0mxm237a7q8gvxvpcqk6zs0rbv725260xdvhd27kibirfjwm4zxl";
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
        { aws ? false
        , aws_region ? "us-east-1"
        , gcp_project ? null
        , name ? defaults.store_name
        , secret ? "${name}-creds"
        , filename ? "${name}-creds.json"
        , namespace ? "external-secrets"
        }: ''
          ---
          ${toYAML (store {inherit name aws aws_region gcp_project secret filename namespace;})}
        '';
      store =
        { name
        , aws
        , aws_region
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
              ${if (gcp_project != null) then "gcpsm" else null} = {
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
              ${if aws then "aws" else null} = {
                service = "SecretsManager";
                region = aws_region;
                auth = {
                  secretRef = {
                    accessKeyIDSecretRef = {
                      inherit namespace;
                      name = secret;
                      key = "access-key";
                    };
                    secretAccessKeySecretRef = {
                      inherit namespace;
                      name = secret;
                      key = "secret-access-key";
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
        , decoding_strategy ? "Auto"
        , extra_data ? [ ]
        , labels ? { }
        , string_data ? { }
        }: ''
          ---
          ${toYAML (secret {inherit name filename env store store_kind refresh_interval secret_ref namespace extract decoding_strategy extra_data labels string_data;})}
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
        , decoding_strategy
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
                extract = {
                  key = if secret_ref == "" then "${env}${name}" else secret_ref;
                  decodingStrategy = decoding_strategy;
                };
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
