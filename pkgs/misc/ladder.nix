# Alternative to 12ft.io. Bypass paywalls with a proxy ladder and remove CORS headers from any URL
{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "ladder";
  version = "0.0.11";

  src = fetchFromGitHub {
    owner = "kubero-dev";
    repo = "ladder";
    rev = "v${version}";
    hash = "sha256-37X9TbFPhxfWKE07VMN2Tb+w3p9EKv9Utcnqq9HuLr8=";
  };

  postPatch = ''
    echo "v${version}" >handlers/VERSION
  '';

  vendorHash = "sha256-0AihQ3KW3iBLqKPm3JK0eHdnZjmABaKDACj3HhoCnoM=";

  ldflags = [ "-s" "-w" ];

  postInstall = ''
    mv $out/bin/cmd $out/bin/ladder
  '';

  meta = with lib; {
    description = "Alternative to 12ft.io. Bypass paywalls with a proxy ladder and remove CORS headers from any URL";
    homepage = "https://github.com/kubero-dev/ladder";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "ladder";
  };
}
