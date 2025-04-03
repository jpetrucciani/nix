# [tlsh](https://github.com/glaslos/tlsh) is a tlsh implementation in go
{ lib, buildGo124Module, fetchFromGitHub }:
let
  version = "0.3.0";
  date = "2022-12-12";
in
buildGo124Module rec {
  inherit version;
  pname = "tlsh-go";

  src = fetchFromGitHub {
    owner = "glaslos";
    repo = "tlsh";
    rev = "v${version}";
    sha256 = "sha256-fDFMF7ajhJ0veylJPoSxOtkkdwcRmR9G7MJgk5fnAdY=";
  };

  ldflags = [
    "-s"
    "-w"
    "-X main.VERSION=${version}"
    "-X main.BUILDDATE=${date}"
  ];

  postInstall = ''
    mv $out/bin/app $out/bin/tlsh
  '';

  vendorHash = null;

  meta = with lib; {
    description = "TLSH lib in Golang";
    homepage = "https://github.com/glaslos/tlsh";
    license = licenses.asl20;
    mainProgram = "tlsh";
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
