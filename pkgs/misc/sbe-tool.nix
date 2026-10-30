# This is a pog wrapper for [simple-binary-encoding](https://github.com/real-logic/simple-binary-encoding)'s `sbe-tool`. It does leverage a pre-compiled jar from my static file hosting.
{ jdk
, pog
}:
let
  version = "1.42.0-momus.1";
  jar = builtins.fetchurl {
    url = "https://static.g7c.us/jar/sbe/sbe-all-${version}.jar";
    sha256 = "1wjzqpd45zwq04yqys11wsvk9mqzbia3bn4ghihq8n2k0xahgg3m";
  };
in
pog {
  inherit version;
  name = "sbe-tool";
  description = "a nix wrapper around the aeron-io/simple-binary-encoding tool for generating code";
  flags =
    let
      langFlag = name: { inherit name; bool = true; short = ""; description = "generate ${name} code for this sbe schema"; };
    in
    [
      { name = "extraflags"; default = ""; description = "extra flags to pass through to the underlying sbe-tool"; }
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
