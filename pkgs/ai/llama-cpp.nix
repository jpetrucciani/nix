{ lib, system, darwin, stdenv, clangStdenv, fetchFromGitHub, writeTextFile }:
let
  inherit (stdenv) isAarch64 isDarwin;
  osSpecific = with darwin.apple_sdk.frameworks; if isDarwin then ([ Accelerate ] ++ (if !isAarch64 then [ CoreGraphics CoreVideo ] else [ ])) else [ ];
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
  version = "master-fb62f92";
in
clangStdenv.mkDerivation rec {
  inherit version;
  name = "llama.cpp";
  src = fetchFromGitHub {
    owner = "ggerganov";
    repo = name;
    rev = "refs/tags/${version}";
    hash = "sha256-iJimbJISIYtKtxzB5tp0ZR8Kc12pEzb3fhtyGaT4rMU=";
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

  meta = with lib; {
    description = "Port of Facebook's LLaMA model in C/C++";
    homepage = "https://github.com/ggerganov/llama.cpp";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
