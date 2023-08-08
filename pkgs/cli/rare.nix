{ lib, buildGo120Module, fetchFromGitHub }:
buildGo120Module rec {
  pname = "rare";
  version = "0.3.1";

  src = fetchFromGitHub {
    owner = "zix99";
    repo = "rare";
    rev = version;
    sha256 = "sha256-p/L9OL5Eo98PcT5vvODy2xdSH7fuIZJQIAfqhdO490Q=";
  };

  vendorHash = "sha256-wUOtxNjL/4MosACCzPTWKWrnMZhxINfN1ppkRsqDh9M=";

  meta = with lib; {
    inherit (src.meta) homepage;
    description =
      "Realtime regex-extraction and aggregation into common formats such as histograms, bar graphs, numerical summaries, tables, and more";
    license = licenses.gpl3Only;
    mainProgram = "rare";
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
