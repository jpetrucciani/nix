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
        rev = "b9bd1d014113b7498f04ad4d28e6021d5f4cddad";
        sha256 = "sha256-HfEKf5K8OLnk34ob9qDjvxi0rm+EFnhQg/fDs0aivI0=";
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
        rev = "235a4115dfe50c63a0290ffb6c70719c9a9341ee";
        sha256 = "sha256-HQ5ybgaaJ60HTJESmQP7e0gXIaYv2beoue/Lt+yXfl0=";
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
