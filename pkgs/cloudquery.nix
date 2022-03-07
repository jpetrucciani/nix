{ stdenv, lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "0.21.1";
  pname = "cloudquery";

  src = fetchFromGitHub {
    owner = "cloudquery";
    repo = "cloudquery";
    rev = "v${version}";
    sha256 = "06ihnvxy255gsmky6pw9xsbxjd1vslnm9vyilj1wy4zjl222hgf3";
  };

  vendorSha256 = "sha256-Y5ZnHV2/U1XzZxcwckrUtOF7kBQrPZdUAuocu72kKvk=";

  checkPhase = ''
    runHook preCheck
    for pkg in $(getGoDirs test); do
      echo "[---] $pkg"
      case "$pkg" in
      ./pkg/client|./pkg/policy|./internal/file)
        echo "[---] skipping '$pkg' test which requires postgres"
        ;;
      ./pkg/ui/console|./internal/getter)
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
