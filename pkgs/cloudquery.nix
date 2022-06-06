{ stdenv, lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "0.24.9";
  pname = "cloudquery";

  src = fetchFromGitHub {
    owner = "cloudquery";
    repo = "cloudquery";
    rev = "v${version}";
    sha256 = "sha256-W2leEkpdhBlvGtT1dCCsJIE7XuUhGjbA8X9oHiPlA/0=";
  };

  vendorSha256 = "sha256-VD6NEyXtCN0cOWmj8nyUOEZglKG1BWzvWamEdiNh/Ic=";

  checkPhase = ''
    runHook preCheck
    for pkg in $(getGoDirs test); do
      echo "[---] $pkg"
      case "$pkg" in
      ./pkg/client|./pkg/policy|./internal/file|./pkg/core/database/postgres)
        echo "[---] skipping '$pkg' test which requires postgres"
        ;;
      ./pkg/ui/console|./internal/getter|./pkg/core|./pkg/core/state|./pkg/plugin/registry)
        echo "[---] skipping '$pkg' test which requires internet"
        ;;
      *)
        buildGoDir test $checkFlags "$pkg"
        ;;
      esac
    done
    runHook postCheck
  '';
  meta = with lib; {
    inherit (src.meta) homepage;
    description =
      "Transform your cloud infrastructure into queryable SQL tables for easy monitoring, governance and security";
    license = licenses.mpl20;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
