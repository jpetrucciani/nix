{ stdenv, lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "0.2.6";
  pname = "kube-linter";

  src = fetchFromGitHub {
    owner = "stackrox";
    repo = "kube-linter";
    rev = version;
    sha256 = "1k9vlxsi3vz9q8xzb1hcjc05wz8x56665lfzix49r091gq0py4cw";
  };

  vendorSha256 = "sha256-HJW28BZ9qFLtdH1qdW8/K4TzHA2ptekXaMF0XnMKbOY=";

  meta = with lib; {
    inherit (src.meta) homepage;
    description =
      "static analysis tool that checks Kubernetes YAML files and Helm charts to ensure the applications represented in them adhere to best practices";
    license = licenses.asl20;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
