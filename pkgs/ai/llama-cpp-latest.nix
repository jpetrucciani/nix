{ llama-cpp, fetchFromGitHub }:
let
  version = "2447";
  src = fetchFromGitHub {
    owner = "ggerganov";
    repo = "llama.cpp";
    rev = "refs/tags/b${version}";
    hash = "sha256-cGB1dtewQIR897mCkqhkv7dHpstF3v1sOC6Q96G7Wyc=";
  };
in
llama-cpp.overrideAttrs (_: {
  inherit src version;
})
