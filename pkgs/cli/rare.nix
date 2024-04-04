# [rare](https://github.com/zix99/rare) is a realtime regex extraction and aggregation cli tool
{ lib, buildGo122Module, fetchFromGitHub }:
buildGo122Module rec {
  pname = "rare";
  version = "0.3.3";

  src = fetchFromGitHub {
    owner = "zix99";
    repo = "rare";
    rev = version;
    sha256 = "sha256-83iHYWMdLOzWDu/WW2TN8D2gUe2Y74aGBUjfHIa9ki8=";
  };

  vendorHash = "sha256-wUOtxNjL/4MosACCzPTWKWrnMZhxINfN1ppkRsqDh9M=";

  meta = with lib; {
    description =
      "Realtime regex-extraction and aggregation into common formats such as histograms, bar graphs, numerical summaries, tables, and more";
    homepage = "https://github.com/zix99/rare";
    license = licenses.gpl3Only;
    mainProgram = "rare";
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
