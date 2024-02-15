{ hex, ... }:
let
  inherit (hex) attrIf ifNotEmptyAttr toYAMLDoc;

  external-secrets = rec {
    defaults = {
      name = "external-secrets";
      namespace = "external-secrets";
      version = "0.9.12";
      sha256 = "1pvg8qxsih5yvn3g5k1ampr80vcc131vspmx4diw9m19bwnrcvhw";
      store_name = "gsm";
    };
    version = rec {
      _v = hex.k8s._.version chart;
      latest = v0-9-12;
      v0-9-12 = _v defaults.version defaults.sha256;
      v0-9-11 = _v "0.9.11" "1aij5xw944gc18whmfqh9qz483c5xlyvv3bl0r7j1i234vkl7zkj";
      v0-9-10 = _v "0.9.10" "1c6qvzmwqndyw5wqs9zkndgl5r269vgi1chw8y9px1fqcywy8j77";
      v0-9-9 = _v "0.9.9" "02i4vjhc38hsvxkffhp6ljh2ijcyni82z0rm4dx4yzd2jb3bxj65";
      v0-9-8 = _v "0.9.8" "1vz9j8dkmxpbidvsxmg5g37d0n07m8yzzwdy9fz60qzrdp200vss";
      v0-9-7 = _v "0.9.7" "18wj8s9zrp8iyxjjmz122gidmfaiy94lf79xz23m92by09i6n2mq";
      v0-9-6 = _v "0.9.6" "0n2lgagviiaxfm3naqnv9nbrs876z6qp767d3l5dll3iwqq1gnv4";
      v0-9-5 = _v "0.9.5" "1rl0hpqvb983l07dlgvzrqbhddpg72ry1q8jlawhv6n0pm32rxb0";
      v0-9-4 = _v "0.9.4" "1zv9yn3qlyjq2c8p8d9x0yas4apkl9q8sg3vhfqcdd6x7cgl8hb5";
      v0-9-3 = _v "0.9.3" "03sgvx2d67qw43k57ks7z7jgycm18m78r2sp8n0frrn8iv8zv5pc";
      v0-9-2 = _v "0.9.2" "0ay81mbz2rj5mj3rpnnh9fx2cfl8ydal2850gq5jd502rgxv5rnq";
      v0-9-1 = _v "0.9.1" "07xcshz6mm2avpfnp806r5bla0aypld0i38kc2ckarqclqwkkvqr";
      v0-8-7 = _v "0.8.7" "0q8pzcxix151b3jsiszz1la6fl98nkwxi7bimhm2zyy0ws532lc0";
      v0-8-6 = _v "0.8.6" "1kimv1kha5614j0aspnk191yzwcbij2p4sw5xvhdxffc5vs3zkc0";
      v0-8-5 = _v "0.8.5" "1hgm886856ijk46spz8pcdks4wpnjg9wn39sw6y6ib26qhl4bn1r";
      v0-8-4 = _v "0.8.4" "1r22vpxrz4skgk14ixlkfyaphyk71wnzpjk989hknzywqysshxb3";
      v0-8-3 = _v "0.8.3" "16rqxlql8ywc99xikh1l1cxm2b8cdi2ak3ydss0i0f6wadyhjmic";
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
        }: toYAMLDoc (store { inherit name aws aws_region gcp_project secret filename namespace; });
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
        }: toYAMLDoc (secret { inherit name filename env store store_kind refresh_interval secret_ref namespace extract decoding_strategy extra_data labels string_data; });

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
