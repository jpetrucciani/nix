{ stdenv, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "0.8.11";
  pname = "cloudquery";

  src = fetchFromGitHub {
    owner = "cloudquery";
    repo = "cloudquery";
    rev = "v${version}";
    sha256 = "0khlw5q8b28hf5zaz3w88mxv69ahjcha9chq661yq55yrimbg3dl";
  };

  vendorSha256 = "SeMhnpBpotdMYWUO/2ERohZvsWk4ekrMNrL00M618k0=";

  meta = with stdenv.lib; {
    homepage = "https://github.com/cloudquery/cloudquery";
    description =
      "cloudquery transforms your cloud infrastructure into queryable SQL tables for easy monitoring, governance and security.";
    license = licenses.mpl20;
  };
}
