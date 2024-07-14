{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "dicedb";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "DiceDB";
    repo = "dice";
    rev = version;
    hash = "sha256-z61rd4BKi/DtQ+PMAJojJs0YM5Bn2VCf2Q8C624aruk=";
  };

  vendorHash = "sha256-q05zDCgzEZv3/5rVXzJkohCvCmeBGc2qoeT93YFdfng=";

  ldflags = [ "-s" "-w" ];

  meta = with lib; {
    description = "A drop-in replacement of Redis with SQL-based realtime reactivity";
    homepage = "https://github.com/DiceDB/dice";
    license = licenses.asl20;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "dicedb";
  };
}
