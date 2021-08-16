{ stdenv, lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "1.1.0";
  pname = "regula";

  src = fetchFromGitHub {
    owner = "fugue";
    repo = "regula";
    rev = "v${version}";
    sha256 = "+qONYtDkZjOGFgYv9i4NZ9lATT7egl/53bPuc5hXFGU=";
    fetchSubmodules = true;
  };

  vendorSha256 = lib.fakeSha256;
  # vendorSha256 = "+rQpXuiyKoR5EcxvmzNrQYfOx15ZOd2EWjspOWNy/8M=";

  preBuild = ''
    go generate ./...
  '';

  meta = with lib; {
    homepage = "https://github.com/fugue/regula";
    description =
      "Check infrastructure as code templates (Terraform, CloudFormation) for AWS, Azure and Google Cloud security and compliance using Open Policy Agent/Rego";
    license = licenses.asl20;
  };
}
