# hex magic module! this contains the helpers that are exposed within the `hex` attribute of the function that makes up a hex file.
pkgs:
rec {
  inherit (pkgs.lib) isList isAttrs isInt isBool isFloat;
  inherit (pkgs.lib) attrNames concatMap concatStringsSep filter substring replaceStrings stringLength;
  inherit (pkgs.lib.strings) toJSON toLower;
  inherit (pkgs.lib.trivial) isFunction;
  inherit (pkgs._std.serde) toTOML;
  annotations = {
    source = "hex";
  };
  flatten = x:
    if isList x
    then concatMap flatten x
    else [ x ];
  flat = x: join (map (y: if isFunction y then y { } else y) (flatten x));
  join = x: concatStringsSep "\n" (flatten x);
  unlines = indent: values: "\n" + concatStringsSep "\n" (map (v: "${indent}${v}") values) + "\n";
  toYAMLDoc = x: ''
    ---
    ${toYAML x}
  '';
  toYAML = _toYAML "";
  _toYAML = indent: value:
    if isAttrs value
    then unlines indent (map (n: "${n}: ${_toYAML (indent + " ") value.${n}}") (attrNames value))
    else if isList value
    then unlines indent (map (v: "- ${_toYAML "${indent} " v}") value)
    else if value == null
    then "null"
    else if isInt value || isFloat value
    then toString value
    else if (isBool value && value)
    then "true"
    else if (isBool value && (! value))
    then "false"
    # isString value
    else ''"${replaceStrings [ ''"'' "\n" ] [ ''\"'' ''\n'' ] value}"'';

  _if = optionalString;
  attrIf = check: name: if check then name else null;
  ifNotNull = check: name: if check != null then name else null;
  ifNotEmptyList = check: name: if builtins.length check != 0 then name else null;
  ifNotEmptyAttr = check: name: if check != { } then name else null;
  optionalString = cond: string: if cond then string else "";
  concatStrings = builtins.concatStringsSep "";
  concatMapStrings = f: list: concatStrings (map f list);
  boolToString = b: if b then "true" else "false";
  hasPrefix = pref: str: substring 0 (stringLength pref) str == pref;
  removePrefix = prefix: str:
    let
      preLen = stringLength prefix;
      sLen = stringLength str;
    in
    if hasPrefix prefix str then
      substring preLen (sLen - preLen) str
    else
      str;
  envAttrToNVP = with pkgs.lib.attrsets; x: filter (x: x.name != "") (mapAttrsToList nameValuePair x);
  defaults = {
    env = rec {
      _field = var: field: {
        name = var;
        valueFrom = {
          fieldRef = {
            fieldPath = field;
          };
        };
      };
      pod_name = _field "POD_NAME" "metadata.name";
      pod_ip = _field "POD_IP" "status.podIP";
    };
  };

  yq_filters = {
    docs_eq = key: values:
      let
        _filter = pkgs.lib.concatStringsSep " or " (map (x: ''${key} == "${x}"'') values);
      in
      ''${_.yq} e -i '. | select(${_filter})' '';
    docs_ne = key: values:
      let
        _filter = pkgs.lib.concatStringsSep " and " (map (x: ''${key} != "${x}"'') values);
      in
      ''${_.yq} e -i '. | select(${_filter})' '';
    secret_metadata = ''${_.yq} e 'del(.metadata | (.annotations,.creationTimestamp,.uid,.resourceVersion))' '';
    crds = ''${_.yq} e -i '. | select(.kind == "CustomResourceDefinition")' '';
    empty = ''${_.yq} e -i 'del(. | select(tag == "!!map" and length == 0))' '';
  };
  yq_magic = {
    delete_key = selectors: key: "${_.yq} e -i 'del(select(${selectors}) | ${key})'";
    crds_filter = yq_filters.docs_ne ".kind" [ "CustomResourceDefinition" ];
    remove_named = names: yq_filters.docs_ne ".metadata.name" names;
  };

  patchYAML =
    { url
    , sha256
    , patch
    , name ? "source"
    , version ? "0.0.1"
    }: builtins.readFile (pkgs.runCommand "${name}-${version}" { src = builtins.fetchurl { inherit url sha256; }; } ''
      ${if isFunction patch then patch _ else patch}
      ${_.prettier} --parser yaml $out
    '');

  _ = rec {
    _cu = "${pkgs.coreutils}/bin";
    cut = "${_cu}/cut";
    head = "${_cu}/head";
    mktemp = "${_cu}/mktemp";
    grep = "${pkgs.gnugrep}/bin/grep";
    sed = "${pkgs.gnused}/bin/sed";
    tail = "${_cu}/tail";
    tr = "${_cu}/tr";
    yq = "${pkgs.yq-go}/bin/yq";
    prettier = "${pkgs.nodePackages.prettier}/bin/prettier --write --config ${_files.prettier_config}";

    _yaml_py = pkgs.python311.withPackages (p: with p; [ pyaml ]);
    yaml_sort = "${_yaml_py} ${_files.yaml_sort}";
    yaml_crds = "${_yaml_py} ${_files.yaml_crds}";

    _files = {
      yaml_crds = pkgs.writeTextFile {
        name = "yamlcrds.py";
        text = ''
          import sys
          import yaml

          if __name__ == "__main__":
              data = sys.stdin.read()
              yaml_docs = [yaml.safe_load(x) for x in data.split("---") if x]
              docs = [x for x in yaml_docs if x and x["kind"] == "CustomResourceDefinition"]
              rendered = "\n---\n".join([yaml.dump(x) for x in docs])
              print(f"---\n{rendered}")
        '';
      };
      yaml_sort = pkgs.writeTextFile {
        name = "yamlsort.py";
        text = ''
          import sys
          import yaml

          def order(data) -> int:
              """given a kubespec, return an ordering"""
              if "kind" not in data:
                  return 10
              if data["kind"] == "Namespace":
                  return 0
              if data["kind"] == "CustomResourceDefinition":
                  return 1
              return 2

          if __name__ == "__main__":
              data = sys.stdin.read()
              yaml_docs = [yaml.safe_load(x) for x in data.split("---") if x]
              docs = [x for x in yaml_docs if x]
              sorted_docs = docs.sort(key=order)
              rendered = "\n---\n".join([yaml.dump(x) for x in sorted_docs])
              print(f"---\n{rendered}")
        '';
      };
      prettier_config = pkgs.writeTextFile {
        name = "prettier.config.js";
        text = ''
          const config = {
            printWidth: 100,
            arrowParens: 'always',
            singleQuote: true,
            tabWidth: 2,
            useTabs: false,
            semi: true,
            bracketSpacing: false,
            bracketSameLine: false,
            requirePragma: false,
            proseWrap: 'preserve',
            trailingComma: 'all',
          };
          module.exports = config;
        '';
      };
    };

  };

  constants = {
    ports = {
      all = "*";
      ssh = "22";
      https = "80,443";
      mysql = "3306";
      postgres = "5432";
      baymax = "10000";
      mongo = "27017";
    };
  };
}
