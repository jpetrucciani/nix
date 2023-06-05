final: prev:
with prev;
{
  ggml = prev.callPackage
    ({ lib, system, darwin, stdenv, clangStdenv, fetchFromGitHub, cmake, git }:
      let
        inherit (stdenv) isAarch64 isDarwin;
        osSpecific = with darwin.apple_sdk_11_0.frameworks; if isDarwin then ([ Accelerate ] ++ (if !isAarch64 then [ CoreGraphics CoreVideo ] else [ ])) else [ ];
      in
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

        buildInputs = osSpecific;
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
