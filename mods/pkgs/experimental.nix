final: prev:
with prev;
let
  inherit (stdenv) isLinux isDarwin isAarch64;
  isM1 = isDarwin && isAarch64;
in
{
  llama-cpp =
    let
      osSpecific = with pkgs.darwin.apple_sdk.frameworks; if isDarwin then [ Accelerate ] else [ ];
      vicunaPrompt = writeTextFile {
        name = "chat-with-vicuna.txt";
        text = ''
          A chat between a curious human and an artificial intelligence assistant. The assistant gives helpful, detailed, and polite answers to the human's questions.

          ### Human: Hello, Assistant.
          ### Assistant: Hello. How may I help you today?
          ### Human: Please tell me the largest city in Europe.
          ### Assistant: Sure. The largest city in Europe is Moscow, the capital of Russia.
          ### Human:
        '';
      };
    in
    clangStdenv.mkDerivation rec {
      name = "llama.cpp";
      src = fetchFromGitHub {
        owner = "ggerganov";
        repo = name;
        rev = "d2beca95dcfcd6f1145886e914b879ffc3604b7a";
        sha256 = "sha256-B2eOjHREaawpdZPIlb5hjPsC24ReURKfxQ8amkxwwxo=";
      };
      cmakeFlags = with pkgs; lib.optionals (system == "aarch64-darwin") [
        "-DCMAKE_C_FLAGS=-D__ARM_FEATURE_DOTPROD=1"
      ];
      installPhase = ''
        mkdir -p $out/bin $out/prompts
        cp ${vicunaPrompt} $out/prompts/vicuna.txt
        mv ./prompts/* $out/prompts/.
        mv ./main $out/bin/llama
        mv ./quantize $out/bin/llama-quantize
      '';
      buildInputs = osSpecific;
    };

  whisper-cpp =
    let
      osSpecific = with pkgs.darwin.apple_sdk.frameworks; if isDarwin then [ Accelerate ] else [ ];
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
      osSpecific = with pkgs.darwin.apple_sdk.frameworks; if isDarwin then [ Accelerate ] else [ ];
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
