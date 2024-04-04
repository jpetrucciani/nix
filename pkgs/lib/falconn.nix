# [falconn](https://github.com/FALCONN-LIB/FALCONN) is a header only NN lookup tool
{ lib
, stdenv
, fetchFromGitHub
, ...
}:

stdenv.mkDerivation rec {
  pname = "falconn";
  version = "1.3.1";

  src = fetchFromGitHub {
    owner = "falconn-lib";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-kz4w3uW3Y45ov7g86MPA3x2WlvBP8EKLVhqeHDKiemk=";
  };

  installPhase = ''
    mkdir -p $out/include
    cp -r ./src/include/falconn $out/include/.
  '';

  meta = with lib; {
    homepage = "https://github.com/FALCONN-LIB/FALCONN";
    description = "Header only FAst Lookups of Cosine and Other Nearest Neighbors";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };

  # This is a header-only library, no point in hydra building it!
  hydraPlatforms = [ ];
}
