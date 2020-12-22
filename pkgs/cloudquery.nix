{ stdenv, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "0.5.5";
  pname = "cloudquery";

  src = fetchFromGitHub {
    owner = "cloudquery";
    repo = "cloudquery";
    rev = "v${version}";
    sha256 = "11y3spcv5ficb31a6niyxjzpdd46j971i6ap3anjki7nij18zyx7";
  };

  vendorSha256 = "127a9bbc6n3k2919qvxi2s3k0rgqfdmpqm7k9vhpksc4day2923h";

  meta = with stdenv.lib; {
    homepage = "https://github.com/cloudquery/cloudquery";
    description =
      "cloudquery transforms your cloud infrastructure into queryable SQL tables for easy monitoring, governance and security.";
    license = licenses.mpl20;
  };
}
