{ stdenv, lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "0.2.0";
  pname = "rare";

  src = fetchFromGitHub {
    owner = "zix99";
    repo = "rare";
    rev = version;
    sha256 = "1is7madj1134vh9jgy3wia61qg6n5ps277ynpw6q8sfr1hidsdj7";
  };

  # vendorSha256 = lib.fakeSha256;
  vendorSha256 = "+rQpXuiyKoR5EcxvmzNrQYfOx15ZOd2EWjspOWNy/8M=";

  meta = with lib; {
    homepage = "https://github.com/zix99/rare/";
    description =
      "Realtime regex-extraction and aggregation into common formats such as histograms, bar graphs, numerical summaries, tables, and more";
    license = licenses.gpl3Only;
  };
}
