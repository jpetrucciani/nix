{ lib, buildGo120Module, fetchFromGitHub }:
buildGo120Module rec {
  pname = "rare";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "zix99";
    repo = "rare";
    rev = version;
    sha256 = "sha256-TL+oqi/q0ObJN08jJur0aaSqey3p/B7bb57vQYYHnF0=";
  };

  vendorHash = "sha256-4+yvgOGlJ33RV0WNJlYUFf/8ergTflMhSn13EJUmVSk=";

  meta = with lib; {
    inherit (src.meta) homepage;
    description =
      "Realtime regex-extraction and aggregation into common formats such as histograms, bar graphs, numerical summaries, tables, and more";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
