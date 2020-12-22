{ stdenv, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "0.4.2";
  pname = "cloudquery";

  src = fetchFromGitHub {
    owner = "cloudquery";
    repo = "cloudquery";
    rev = "v${version}";
    sha256 = "1zf3xiyfz35jdn0gvhsskv06iqcrp16b0qqh6v6lwkiv5fgfcxg5";
  };

  vendorSha256 = "1rv8ry2xdapjcj1bnbrh5pkq1jfnnqqv1sfv1vcmgavpi2paw6hm";

  meta = with stdenv.lib; {
    homepage = "https://github.com/cloudquery/cloudquery";
    description =
      "cloudquery transforms your cloud infrastructure into queryable SQL tables for easy monitoring, governance and security.";
    license = licenses.mpl20;
  };
}
