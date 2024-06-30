# [smoothmq](https://github.com/poundifdef/SmoothMQ) is A drop-in replacement for SQS designed for great developer experience and efficiency
{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule {
  pname = "smoothmq";
  version = "unstable-2024-06-30";

  src = fetchFromGitHub {
    owner = "poundifdef";
    repo = "SmoothMQ";
    rev = "46f8b2266d604cf1a9793338ec7d1a1caad2dc4b";
    hash = "sha256-4AnpT5BkROkR+fsfv/KYsvvA+qpgvJ9Pk3tBor0QSRQ=";
  };

  vendorHash = "sha256-bEVliwjw8dDiS/0/ImIDIs+fMACzcSYiFAxB1mz96lE=";

  ldflags = [ "-s" "-w" ];

  postInstall = ''
    mv $out/bin/{q,smoothmq}
  '';

  meta = with lib; {
    description = "A drop-in replacement for SQS designed for great developer experience and efficiency";
    homepage = "https://github.com/poundifdef/SmoothMQ";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "smoothmq";
  };
}
