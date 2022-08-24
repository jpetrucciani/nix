with builtins;
rec {
  flatten = x:
    if isList x
    then concatMap flatten x
    else [ x ];
  join = x: concatStringsSep "\n" (flatten x);
  flattenCharts = x: join (map (y: if isFunction y then y { } else y) (flatten x));
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
  attrIf = check: name: if check then name else null;
  attrIfNotNull = check: name: if check != null then name else null;
}
