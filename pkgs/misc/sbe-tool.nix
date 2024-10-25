# This is a pog wrapper for [simple-binary-encoding](https://github.com/real-logic/simple-binary-encoding)'s `sbe-tool`. It does leverage a pre-compiled jar from my static file hosting.
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
  flags =
    let
      langFlag = name: { inherit name; bool = true; short = ""; };
    in
    [
      { name = "extraflags"; default = ""; }
      (langFlag "c")
      (langFlag "cpp")
      (langFlag "csharp")
      (langFlag "golang")
      (langFlag "rust")
    ];
  script = h:
    let
      invoke = class: ''${jdk}/bin/java -Dsbe.target.language=${class} $extraflags -jar ${jar} "$@"'';
      lang = flag: class: ''
        # shellcheck disable=SC2086
        ${h.flag flag} && ${invoke class}
      '';
    in
    ''
      ${lang "c" "C"}
      ${lang "cpp" "CPP"}
      ${lang "csharp" "uk.co.real_logic.sbe.generation.csharp.CSharp"}
      ${lang "golang" "Golang"}
      ${lang "rust" "Rust"}
    '';
}
