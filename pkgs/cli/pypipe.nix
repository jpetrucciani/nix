# [pypipe](https://github.com/bugen/pypipe) is a python pipe cli tool
{ lib
, stdenv
, fetchFromGitHub
, python311
, ...
}:

stdenv.mkDerivation rec {
  pname = "pypipe";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "bugen";
    repo = pname;
    rev = "eb7b0456cdf728a7203fcec7e7974c24ea721f8e";
    sha256 = "sha256-Knj91Z+RmcP8142PabmbFx1RR74xR6fb99HcPXph1wA=";
  };

  installPhase = ''
    mkdir -p $out/bin
    echo "#!${python311}/bin/python" >$out/bin/ppp
    tail -n +2 $src/pypipe.py >>$out/bin/ppp
    chmod +x $out/bin/ppp
  '';

  meta = with lib; {
    description = "Python pipe command line tool";
    homepage = "https://github.com/bugen/pypipe";
    mainProgram = "ppp";
    license = licenses.asl20;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
