{ stdenv, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "0.7.4";
  pname = "cloudquery";

  src = fetchFromGitHub {
    owner = "cloudquery";
    repo = "cloudquery";
    rev = "v${version}";
    sha256 = "1dybarkijj33ja9zj136n45jjdzr4xknws6lz7b45zv7dkmfp8f0";
  };

  vendorSha256 = "1zh8l3cbz81x1w17wqbv6v0mhq47cgxi6zbs2hl4yyq3v811hlrj";

  meta = with stdenv.lib; {
    homepage = "https://github.com/cloudquery/cloudquery";
    description =
      "cloudquery transforms your cloud infrastructure into queryable SQL tables for easy monitoring, governance and security.";
    license = licenses.mpl20;
  };
}
