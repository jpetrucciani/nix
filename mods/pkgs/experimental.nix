# extra experimental packages
final: prev:
let
  inherit (final) callPackage;
in
{
  ggml = callPackage
    ({ lib, system, clangStdenv, fetchFromGitHub, cmake, git }:
      clangStdenv.mkDerivation rec {
        name = "ggml";
        version = "0.0.0";

        src = fetchFromGitHub {
          owner = "ggerganov";
          repo = name;
          rev = "2a75bd43113702fe096c75408b300d106be90a58";
          hash = "sha256-3IgIes8x5yoHwcVJV67kizV95ZocrTd29bmrbKJBRzU=";
        };
        cmakeFlags = lib.optionals (system == "aarch64-darwin") [
          "-DCMAKE_C_FLAGS=-D__ARM_FEATURE_DOTPROD=1"
        ];

        buildPhase = ''
          cmake .
          cmake --build . --config Release
        '';

        installPhase = ''
          mkdir -p $out/bin
          mv ./bin/{mpt,replit,starcoder,whisper} $out/bin/.
        '';

        nativeBuildInputs = [ cmake git ];

        meta = with lib; {
          description = "Tensor library for machine learning";
          homepage = "https://github.com/ggerganov/ggml";
          mainProgram = "mpt";
          license = licenses.mit;
          maintainers = with maintainers; [ jpetrucciani ];
        };
      }
    )
    { };
}
