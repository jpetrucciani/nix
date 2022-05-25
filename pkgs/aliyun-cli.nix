{ stdenv, lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  version = "3.0.121";
  pname = "aliyun-cli";

  src = fetchFromGitHub {
    owner = "aliyun";
    repo = "aliyun-cli";
    rev = "v${version}";
    sha256 = "sha256-1D1JZZ/KMC4oZRaYvWpUazTk7llvX5WHPBxWEGCiKrI=";
    fetchSubmodules = true;
  };

  # don't run check as it deletes directories relative to this dir
  doCheck = false;

  # move the output 'main' to the name of the executable
  postInstall = ''
    mv $out/bin/main $out/bin/aliyun
  '';

  vendorSha256 = "sha256-f3GXkAvTe8rPFWCR5TM4mDK/VOQWt2lrZrfJ/Wvw8Uc=";

  meta = with lib; {
    inherit (src.meta) homepage;
    description =
      "A tool to manage and use Alibaba Cloud resources through a command line interface";
    license = licenses.asl20;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
