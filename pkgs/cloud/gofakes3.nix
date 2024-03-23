{ lib, buildGo122Module, fetchFromGitHub }:
buildGo122Module rec {
  pname = "gofakes3";
  version = "0.0.0";

  src = fetchFromGitHub {
    owner = "johannesboyne";
    repo = pname;
    rev = "c0edf658332badad9eb3a69f44dbdcbfec487a68";
    hash = "sha256-aToCIEkjfoQzG5+RyiLCK5IyEYyj3rJ9OoSm8lRMiVc=";
  };

  ldflags = [
    "-s"
    "-w"
  ];

  vendorHash = "sha256-5Q2X0Wl/ltpP5SFr9TUbirISNL7IAyaDUkcESwqss/g=";

  meta = with lib; {
    description = "A simple fake AWS S3 object storage (used for local test-runs against AWS S3 APIs)";
    homepage = "https://github.com/johannesboyne/gofakes3";
    mainProgram = "gofakes3";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
