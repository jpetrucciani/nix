{ stdenv, lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "0.14.2";
  pname = "cloudquery";

  src = fetchFromGitHub {
    owner = "cloudquery";
    repo = "cloudquery";
    rev = "v${version}";
    sha256 = "1mf6kb0iq3lfhjvsdfa0rsv4bhwh6xzwjx8xxwzdfyaw82h7wl7i";
  };

  # vendorSha256 = lib.fakeSha256;
  vendorSha256 = "92JrlbkWR2QxCkFu/1mJnPQ/9vD3ZMIBRD1kG1/xaP8=";
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
  };
}
