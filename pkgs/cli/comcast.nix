{ lib, buildGo122Module, fetchFromGitHub }:
buildGo122Module rec {
  pname = "comcast";
  version = "1.0.1";

  # this is forked to fix go mod stuff
  src = fetchFromGitHub {
    owner = "jpetrucciani";
    repo = "comcast";
    rev = "93b2589b3e677c4f351c2ee7bf8709ce762ca697";
    hash = "sha256-jfVxoKkZscemOdlyQNFXckhlEcl7UZ+MPoIQu2lcUaE=";
  };

  vendorHash = "sha256-AruaKBvPmHw13NTr0folQW1HouRVMW5M3gbFWT1tF/s=";

  # disable checks because they need networking
  doCheck = false;

  meta = with lib; {
    inherit (src.meta) homepage;
    description = "Simulating shitty network connections so you can build better systems";
    license = licenses.asl20;
    mainProgram = "comcast";
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
