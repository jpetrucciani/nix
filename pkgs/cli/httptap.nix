# [httptap](https://github.com/monasticacademy/httptap) is a program that lets you view HTTP/HTTPS requests made by any Linux program 
{ lib
, buildGoModule
, fetchFromGitHub
, libpcap
}:

buildGoModule {
  pname = "httptap";
  version = "0.0.8";

  src = fetchFromGitHub {
    # i've forked this to fix go.mod
    # owner = "monasticacademy";
    owner = "jpetrucciani";
    repo = "httptap";
    # rev = "v${version}";
    rev = "3b520725c784d6435be6a51c58ae847bae729962";
    hash = "sha256-iKkClDlh78mOGEltsPde8xtMoutezKzFg5r4TIhbDZo=";
  };

  vendorHash = "sha256-+TtHw2KdeNHCgnMnkxJJ9shqsrlbeTzYwbPH0dJmCjM=";

  buildInputs = [
    libpcap
  ];

  env.CGO_ENABLED = 0;

  subPackages = [
    "."
  ];

  ldflags = [ "-s" "-w" ];

  meta = {
    description = "View HTTP/HTTPS requests made by any Linux program";
    homepage = "https://github.com/monasticacademy/httptap";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "httptap";
  };
}
