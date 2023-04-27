final: prev:
with prev;
let
  inherit (stdenv) isDarwin;
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
        rev = "0b2da20538d01926b77ea237dd1c930c4d20b686";
        hash = "sha256-iOp2xzWLqFplA99BXc+0ytz+zXmey4SLXkr00/+TAas=";
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
        hash = "sha256-mzRw9kUW6BtmK8AHoliD2/QEOeM+uiWhNll+xq3/eEc=";
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
        rev = "a0c74a70194284e943020cb43d8072a048aaeec5";
        hash = "sha256-1WyqOhq3MjnVevqgQALKE8+AvET1kQYo7wXuSG6ZpmE=";
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
