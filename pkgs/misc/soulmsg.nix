{ stdenv, lib, buildGo120Module, fetchFromGitHub, ... }:
buildGo120Module rec {
  pname = "soulmsg";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "derricw";
    repo = pname;
    rev = "f75090b5927ec7ea44725fc37c01dcdbfacf6948";
    sha256 = "sha256-fZ3a5Ak87iugdYceUVMe7u1mVa2FMeuUH0T8MA01boM=";
  };

  vendorHash = "sha256-vanKL5s+szW0hduUXGnJNUlyu8wZ2HsBVklIUb/+DLY=";

  ldflags = [
    "-s"
    "-w"
  ];

  meta = with lib; {
    description = "";
    homepage = "https://github.com/derricw/soulmsg";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
