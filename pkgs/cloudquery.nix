{ stdenv, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "0.9.6";
  pname = "cloudquery";

  src = fetchFromGitHub {
    owner = "cloudquery";
    repo = "cloudquery";
    rev = "v${version}";
    sha256 = "06316ji2d887wiw7w1dwnbm4rj3ryy672c43sxf48yq0b65887z0";
  };

  vendorSha256 = "tpGyE8m5ksvg+N7ICnNBhD0sWjeI4yBcHlLwqbDyBmc=";

  meta = with stdenv.lib; {
    homepage = "https://github.com/cloudquery/cloudquery";
    description =
      "cloudquery transforms your cloud infrastructure into queryable SQL tables for easy monitoring, governance and security.";
    license = licenses.mpl20;
  };
}
