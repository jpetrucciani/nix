{ stdenv, lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "1.3.0";
  pname = "rbac-tool";

  src = fetchFromGitHub {
    owner = "alcideio";
    repo = pname;
    rev = "v${version}";
    sha256 = "1w77w3r0inygfbbwraiif0hx845ghq5h81h455p4jk9spv1np3fn";
  };

  # vendorSha256 = lib.fakeSha256;
  vendorSha256 = "o95BHQMv24UbBBadEKOFz/hiUHR35kCcN0wr76pZhTU=";

  meta = with lib; {
    homepage = "https://github.com/${src.owner}/${src.repo}";
    description = "Visualize, Analyze, Generate & Query RBAC policies in Kubernetes";
    license = licenses.asl20;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
