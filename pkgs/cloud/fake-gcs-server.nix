{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "fake-gcs-server";
  version = "1.47.7";

  src = fetchFromGitHub {
    owner = "fsouza";
    repo = "fake-gcs-server";
    rev = "v${version}";
    hash = "sha256-TM6lJLlxcdZjcW1MyXzlqXIntEAZgiy3fqxrxP5VduQ=";
  };

  doCheck = false;

  postPatch = ''
    sed -i -E 's#"/var/tmp"#os.TempDir()#g' \
      internal/grpc/server_test.go \
      fakestorage/bucket_test.go \
      internal/backend/backend_test.go
  '';

  vendorHash = "sha256-DhOaZ2iFhedpc/j1RA8jthTGPRNR5LZQvVc+CAO3V7M=";

  ldflags = [
    "-s"
    "-w"
  ];

  meta = with lib; {
    description = "Google Cloud Storage emulator & testing library";
    homepage = "https://github.com/fsouza/fake-gcs-server";
    license = licenses.bsd2;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "fake-gcs-server";
  };
}
