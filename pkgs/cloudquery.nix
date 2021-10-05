{ stdenv, lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "0.15.4";
  pname = "cloudquery";

  src = fetchFromGitHub {
    owner = "cloudquery";
    repo = "cloudquery";
    rev = "v${version}";
    sha256 = "1wffhl0w5xpgc3w176gh2b1x8rh78h35v83gfwrdmkb7ad2rhbsm";
  };

  # vendorSha256 = lib.fakeSha256;
  vendorSha256 = "W9yq9aSz0Bn8s+GMX7EoNxiZpWkAWOFVrB2k40kNJtA=";

  checkPhase = ''
    runHook preCheck
    for pkg in $(getGoDirs test); do
      echo "[---] $pkg"
      case "$pkg" in
      ./pkg/client|./pkg/policy|./internal/file)
        echo "[---] skipping '$pkg' test which requires postgres"
        ;;
      *)
        buildGoDir test $checkFlags "$pkg"
        ;;
      esac
    done
    runHook postCheck
  '';
  meta = with lib; {
    homepage = "https://github.com/${src.owner}/${src.repo}";
    description =
      "Transform your cloud infrastructure into queryable SQL tables for easy monitoring, governance and security";
    license = licenses.mpl20;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
