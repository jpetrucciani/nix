pkgs:
with builtins;
rec {
  flatten = x:
    if isList x
    then concatMap flatten x
    else [ x ];
  flat = x: join (map (y: if isFunction y then y { } else y) (flatten x));
  join = x: concatStringsSep "\n" (flatten x);
  unlines = indent: values: "\n" + concatStringsSep "\n" (map (v: "${indent}${v}") values) + "\n";
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

  _ = rec {
    sed = "${pkgs.gnused}/bin/sed";
    yq = "${pkgs.yq-go}/bin/yq";
    prettier = "${pkgs.nodePackages.prettier}/bin/prettier --write --config ${_files.prettier_config}";

    _yaml_sort_py = pkgs.python310.withPackages (p: with p; [ pyaml ]);
    yaml_sort = "${_yaml_sort_py} ${_files.yaml_sort}";

    _files = {
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
              rendered = "\n---\n".join([yaml.dump(x) for x in docs])
              print(f"---\n{rendered}")
        '';
      };
      prettier_config = pkgs.writeTextFile {
        name = "prettierrc.js";
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

  constants = rec {
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
