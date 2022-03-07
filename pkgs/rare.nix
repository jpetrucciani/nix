{ stdenv, lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "0.2.1";
  pname = "rare";

  src = fetchFromGitHub {
    owner = "zix99";
    repo = "rare";
    rev = version;
    sha256 = "1v2f31rcn5h7daqvg2rdqcjvgw19afd4whpnc9xpskjcyrr9lisp";
  };

  vendorSha256 = "sha256-mswPEdhuHLjsLFXMczdHiK30Gn4whDrigees4pqUDC4=";

  meta = with lib; {
    inherit (src.meta) homepage;
    description =
      "Realtime regex-extraction and aggregation into common formats such as histograms, bar graphs, numerical summaries, tables, and more";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
