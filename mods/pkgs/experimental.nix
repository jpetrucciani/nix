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
        rev = "73c6ed5e8784a20f89d51b1703a09bc690c68227";
        sha256 = "sha256-+5sfSKnCk7+Vpx58ahxi9Bw6yJxDwEFf239PFD+h/iM=";
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
      installPhase = ''
        mkdir -p $out/bin
        mv ./main $out/bin/whisper
      '';
      buildInputs = osSpecific;
    };
}
