{ stdenv, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "0.12.1";
  pname = "cloudquery";

  src = fetchFromGitHub {
    owner = "cloudquery";
    repo = "cloudquery";
    rev = "v${version}";
    sha256 = "03jfiz8mzp3hxdyk45yfqms9vgq4pqa8ix83px1gmhisrhbykc4k";
  };

  # vendorSha256 = stdenv.lib.fakeSha256;
  vendorSha256 = "HdFdpSocjfOmzAcXCp31OY/y+z/N9Ze7rekMAmx2Rqo=";

  meta = with stdenv.lib; {
    homepage = "https://github.com/cloudquery/cloudquery";
    description =
      "cloudquery transforms your cloud infrastructure into queryable SQL tables for easy monitoring, governance and security.";
    license = licenses.mpl20;
  };
}
