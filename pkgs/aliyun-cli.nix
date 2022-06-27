{ stdenv, lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "3.0.123";
  pname = "aliyun-cli";

  src = fetchFromGitHub {
    owner = "aliyun";
    repo = "aliyun-cli";
    rev = "v${version}";
    sha256 = "sha256-68u31s7SsRRT9OQpTqlhAs5Dx+ggbTTSeKYBByiqn6g=";
    fetchSubmodules = true;
  };

  # don't run check as it deletes directories relative to this dir
  doCheck = false;

  # move the output 'main' to the name of the executable
  postInstall = ''
    mv $out/bin/main $out/bin/aliyun
  '';

  vendorSha256 = "sha256-X5r89aI7UdVlzEJi8zaOzwTETwb+XH8dKO6rVe//FNs=";

  meta = with lib; {
    inherit (src.meta) homepage;
    description =
      "A tool to manage and use Alibaba Cloud resources through a command line interface";
    license = licenses.asl20;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
