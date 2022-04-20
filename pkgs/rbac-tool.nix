{ stdenv, lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "1.6.3";
  pname = "rbac-tool";

  src = fetchFromGitHub {
    owner = "alcideio";
    repo = pname;
    rev = "v${version}";
    sha256 = "1baaiczs06kg15bkmgkrlwi6wlg6jygv1bavvgh019njs44pvir6";
  };

  vendorSha256 = "sha256-kIsKRWXOJzb33T0fM9dZCXlzDdu3SUIGyxNgSH7G4xY=";

  meta = with lib; {
    inherit (src.meta) homepage;
    description = "Visualize, Analyze, Generate & Query RBAC policies in Kubernetes";
    license = licenses.asl20;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
