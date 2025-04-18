# [s3-edit](https://github.com/tsub/s3-edit) is a cli tool for editing s3 files directly
{ lib, buildGo124Module, fetchFromGitHub }:
buildGo124Module rec {
  pname = "s3-edit";
  version = "0.0.16";

  src = fetchFromGitHub {
    owner = "tsub";
    repo = "s3-edit";
    rev = "v${version}";
    hash = "sha256-BNFbg3IRsLOdakh8d53P0FSOGaGXYJuexECPlCMWCC0=";
  };

  ldflags = [
    "-s"
    "-w"
    "-X cmd.version=${version}"
  ];

  vendorHash = "sha256-ZM5Z3yLOwOYpOTyoXmSbyPFBE31F+Jvc6DN4rmHmyt0=";

  meta = with lib; {
    description = "Edit directly a file on Amazon S3 in CLI";
    homepage = "https://github.com/tsub/s3-edit";
    license = licenses.mit;
    mainProgram = "s3-edit";
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
