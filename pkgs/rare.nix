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

  # vendorSha256 = lib.fakeSha256;
  vendorSha256 = "DZ/JLcnU+xmwkZ5U7E7Hw3JPPyuNeMEcZyX8g7sOdVI=";

  meta = with lib; {
    homepage = "https://github.com/${src.owner}/${src.repo}";
    description =
      "Realtime regex-extraction and aggregation into common formats such as histograms, bar graphs, numerical summaries, tables, and more";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
