{ stdenv, lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "1.6.3";
  pname = "rbac-tool";

  src = fetchFromGitHub {
    owner = "alcideio";
    repo = pname;
    rev = "v${version}";
    sha256 = "1w77w3r0inygfbbwraiif0hx845ghq5h81h455p4jk9spv1np3fn";
  };

  vendorSha256 = "sha256-o95BHQMv24UbBBadEKOFz/hiUHR35kCcN0wr76pZhTU=";

  meta = with lib; {
    inherit (src.meta) homepage;
    description = "Visualize, Analyze, Generate & Query RBAC policies in Kubernetes";
    license = licenses.asl20;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
