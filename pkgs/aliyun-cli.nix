{ stdenv, lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "3.0.94";
  pname = "aliyun-cli";

  src = fetchFromGitHub {
    owner = "aliyun";
    repo = "aliyun-cli";
    rev = "v${version}";
    sha256 = "Q5ppEkX7055makcqw8/tB6j+ERJH3ULuZrH3mW77OdE=";
    fetchSubmodules = true;
  };

  # don't run check as it deletes directories relative to this dir
  doCheck = false;

  # move the output 'main' to the name of the executable
  postInstall = ''
    mv $out/bin/main $out/bin/aliyun
  '';

  # vendorSha256 = lib.fakeSha256;
  vendorSha256 = "c7LsCNcxdHwDBEknXJt9AyrmFcem8YtUYy06vNDBdDY=";

  meta = with lib; {
    inherit (src.meta) homepage;
    description =
      "A tool to manage and use Alibaba Cloud resources through a command line interface";
    license = licenses.asl20;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
