{ jdk
, pog
}:
let
  version = "1.34.0";
  jar = builtins.fetchurl {
    url = "https://cobi.dev/static/jar/sbe/sbe-all-${version}-SNAPSHOT.jar";
    sha256 = "1mlawqkggd1yzhhis4gk1vy52va2ffb9hm5h2fg6763h8x5mgsyd";
  };
in
pog {
  inherit version;
  name = "sbe-tool";
  flags = [{ name = "extraflags"; default = ""; }];
  script = ''
    # shellcheck disable=SC2086
    ${jdk}/bin/java $extraflags -jar ${jar} "$@"
  '';
}
