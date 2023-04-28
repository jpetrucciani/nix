{ lib, system, darwin, isDarwin, clangStdenv, fetchFromGitHub, writeTextFile }:
let
  osSpecific = with darwin.apple_sdk.frameworks; if isDarwin then [ Accelerate ] else [ ];
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
    rev = "11d902364b0e3b503a02a4e757ee2dc38aacb68f";
    hash = "sha256-CQg6xCHSLpJjItdvEg2b1MDw3qyEv3pK0DcCxcxHgrs=";
  };
  cmakeFlags = lib.optionals (system == "aarch64-darwin") [
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
}
