{ hex, pkgs }:
let
  inherit (hex) concatMapStrings _if;
  inherit (hex._) prettier sed yaml_sort yq;
  constants = {
    flags = {
      create-namespace = "--create-namespace";
    };
  };
  helm = rec {
    defaults = {
      external-secrets =
        { name ? "external-secrets"
        , namespace ? "external-secrets"
        , values ? [ ]
        , sets ? [ "installCRDs=true" ]
        , version ? "0.5.9"
        , sha256 ? "0mxm237a7q8gvxvpcqk6zs0rbv725260xdvhd27kibirfjwm4zxl"
        , extraFlags ? [ constants.flags.create-namespace ]
        }: build {
          inherit name namespace values sets version sha256 extraFlags;
          url = charts.url.external-secrets version;
        };
    };
    charts = {
      url = rec {
        _ = rec {
          github = { org, repo, repoName, chartName ? repoName, version }: "https://github.com/${org}/${repo}/releases/download/${repoName}-${version}/${chartName}-${version}.tgz";
        };
        external-secrets = version: _.github {
          inherit version;
          org = "external-secrets";
          repo = "external-secrets";
          repoName = "helm-chart";
          chartName = "external-secrets";
        };
      };
    };
    build = args: ''
      ---
      ${builtins.readFile (chart args).template}
    '';
    chart =
      { name
      , url
      , sha256
      , namespace ? "default"
      , values ? [ ]
      , sets ? [ ]
      , version ? "0.0.0"
      , includeCRDs ? true
      , extraFlags ? [ ]
      , forceNamespace ? false
      , prettify ? true
      , sortYaml ? false
      }:
      rec {
        chartFiles = fetchTarball {
          inherit url sha256;
        };
        template = pkgs.runCommand "${name}-${version}-rendered.yaml" { } ''
          ls -alF
          ${pkgs.kubernetes-helm}/bin/helm template \
            --namespace '${namespace}' \
            ${_if includeCRDs "--include-crds"} \
            ${name} \
            ${concatMapStrings (x: "--values ${x} ") values} \
            ${concatMapStrings (x: "--set '${x}' ") sets} \
            ${concatMapStrings (x: "${x} ") extraFlags} \
            ${chartFiles} \
            >$out

          # remove empty docs
          ${sed} -z -i 's#---(\n+---)*#---#g' $out

          # force namespace (optional)
          ${_if forceNamespace ''${yq} e -i '(select (tag == "!!map" or tag== "!!seq") | .metadata.namespace) = "${namespace}"' $out''}
          ${_if forceNamespace ''${yq} e -i 'with (.items[]; .metadata.namespace = "${namespace}")' $out''}
          ${_if forceNamespace ''${yq} e -i 'del(.items | select(length==0))' $out''}
          ${_if forceNamespace ''${sed} -E -z -i 's#---(\n+\{\}\n+---)*#---#g' $out''}
          ${_if sortYaml ''${yaml_sort} <$out >$out.tmp''}
          ${_if sortYaml ''mv $out.tmp $out''}
          ${_if prettify ''${prettier} --parser yaml $out''}
        '';
      };
  };
in
helm
