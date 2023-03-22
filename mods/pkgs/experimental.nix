final: prev:
with prev;
let
  inherit (stdenv) isLinux isDarwin isAarch64;
  isM1 = isDarwin && isAarch64;
in
{
  llama-cpp =
    let
      osSpecific = with pkgs.darwin.apple_sdk.frameworks; if isDarwin then [ Security AppKit ] else [ ];
    in
    clangStdenv.mkDerivation rec {
      name = "llama.cpp";
      src = fetchFromGitHub {
        owner = "ggerganov";
        repo = name;
        rev = "da0e9fe90ccf6e73597eb19dd0cfc0a28363fb3b";
        sha256 = "sha256-LwwAwoKug1DawfCirW6qQkyifhONH/5OfjM7p9QQ9mM=";
      };
      installPhase = ''
        mkdir -p $out/bin
        mv ./main $out/bin/llama
        mv ./quantize $out/bin/llama-quantize
      '';
      buildInputs = osSpecific;
    };

  whisper-cpp =
    let
      osSpecific = with pkgs.darwin.apple_sdk.frameworks; if isDarwin then [ Security AppKit ] else [ ];
    in
    clangStdenv.mkDerivation rec {
      name = "whisper.cpp";
      src = fetchFromGitHub {
        owner = "ggerganov";
        repo = name;
        rev = "09e90680072d8ecdf02eaf21c393218385d2c616";
        sha256 = "sha256-mzRw9kUW6BtmK8AHoliD2/QEOeM+uiWhNll+xq3/eEc=";
      };
      postBuild = ''
        make stream
      '';
      installPhase = ''
        mkdir -p $out/bin
        mv ./main $out/bin/whisper
        mv ./stream $out/bin/whisper-stream
      '';
      buildInputs = with pkgs; [
        SDL2
      ] ++ osSpecific;
    };


  alpaca-cpp =
    let
      osSpecific = with pkgs.darwin.apple_sdk.frameworks; if isDarwin then [ Security AppKit ] else [ ];
    in
    clangStdenv.mkDerivation rec {
      name = "alpaca.cpp";
      src = fetchFromGitHub {
        owner = "antimatter15";
        repo = name;
        rev = "c5ae5d08a56b82c17ef8121bc01221924576ad28";
        sha256 = "sha256-5uzrB+r0KpG4jcL6Hd3voeARXlEv+2dvltaCcql5VIc=";
      };
      buildPhase = ''
        make chat
      '';
      installPhase = ''
        mkdir -p $out/bin
        cp ./chat $out/bin/chat
        mv ./chat $out/bin/alpaca-chat
      '';
      buildInputs = osSpecific;
    };
}
