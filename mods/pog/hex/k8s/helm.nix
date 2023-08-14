{ hex, pkgs }:
let
  inherit (builtins) isFunction readFile;
  inherit (hex) concatMapStrings _if;
  inherit (hex._) prettier sed yaml_sort yq;
  helm = rec {
    constants = {
      flags = {
        create-namespace = "--create-namespace";
      };
      ports = {
        all = "*";
        ftp = "21";
        ssh = "22";
        smtp = "25";
        https = "80,443";
        mysql = "3306";
        postgres = "5432";
        mongo = "27017";
      };
    };
    charts = {
      url = {
        github = { org, repo, repoName, chartName ? repoName, version }: "https://github.com/${org}/${repo}/releases/download/${repoName}-${version}/${chartName}-${version}.tgz";
      };
    };
    build = args: ''
      ---
      ${readFile (chart args).template}
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
      , preRender ? ""
      , postRender ? ""
      , prettify ? true
      , sortYaml ? false
      , kubeVersion ? "1.27"
      }:
      rec {
        chartFiles = fetchTarball {
          inherit url sha256;
        };
        hookParams = {
          inherit chartFiles;
        };
        preRenderText = if isFunction preRender then preRender hookParams else preRender;
        postRenderText = if isFunction postRender then postRender hookParams else postRender;
        template =
          let
            temp = "./rendered.yaml";
          in
          pkgs.runCommand "${name}-${version}-rendered.yaml" { } ''
            cp -r ${chartFiles}/* .
            ${preRenderText}
            ${pkgs.kubernetes-helm}/bin/helm template \
              --namespace '${namespace}' \
              --kube-version '${kubeVersion}' \
              ${_if includeCRDs "--include-crds"} \
              ${name} \
              ${concatMapStrings (x: "--values ${x} ") values} \
              ${concatMapStrings (x: "--set '${x}' ") sets} \
              ${concatMapStrings (x: "${x} ") extraFlags} \
              . >${temp}

            # remove empty docs
            ${sed} -E -z -i 's#---(\n+---)*#---#g' ${temp}

            # force namespace (optional)
            ${_if forceNamespace ''${yq} e -i '(select (tag == "!!map" or tag== "!!seq") | .metadata.namespace) = "${namespace}"' ${temp}''}
            ${_if forceNamespace ''${yq} e -i 'with (.items[]; .metadata.namespace = "${namespace}")' ${temp}''}
            ${_if forceNamespace ''${yq} e -i 'del(.items | select(length==0))' ${temp}''}
            ${_if forceNamespace ''${sed} -E -z -i 's#---(\n+\{\}\n+---)*#---#g' ${temp}''}
            ${postRenderText}
            ${_if sortYaml ''${yaml_sort} <${temp} >${temp}.tmp''}
            ${_if sortYaml ''mv ${temp}.tmp ${temp}''}
            ${_if prettify ''${prettier} --parser yaml ${temp}''}
            cp ${temp} $out
          '';
      };
  };
in
helm
