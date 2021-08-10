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
      if [ "$pkg" = "./pkg/client" -o "$pkg" = "./pkg/policy"  ]; then
        echo "[---] skipping '$pkg' test which requires postgres"
      else
        buildGoDir test $checkFlags "$pkg"
      fi
    done
    runHook postCheck
  '';
  meta = with lib; {
    homepage = "https://github.com/cloudquery/cloudquery";
    description =
      "cloudquery transforms your cloud infrastructure into queryable SQL tables for easy monitoring, governance and security.";
    license = licenses.mpl20;
  };
}
