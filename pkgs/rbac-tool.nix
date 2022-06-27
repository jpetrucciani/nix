{ stdenv, lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "1.7.1";
  pname = "rbac-tool";

  src = fetchFromGitHub {
    owner = "alcideio";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-G3VhByaCB1GSub56WehaH+v5GobR3YulNtH13wQDG6w=";
  };

  vendorSha256 = "sha256-nADcFaVdC3UrZxqrwqjcNho/80n856Co2KG0AknflWM=";

  meta = with lib; {
    inherit (src.meta) homepage;
    description = "Visualize, Analyze, Generate & Query RBAC policies in Kubernetes";
    license = licenses.asl20;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
