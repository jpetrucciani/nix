{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "fake-gcs-server";
  version = "1.47.8";

  src = fetchFromGitHub {
    owner = "fsouza";
    repo = "fake-gcs-server";
    rev = "v${version}";
    hash = "sha256-7xvqxBTYGlO8cBQcNVnrH6TGUllLq9Lgsh4fYn5LCnE=";
  };

  doCheck = false;

  postPatch = ''
    sed -i -E 's#"/var/tmp"#os.TempDir()#g' \
      internal/grpc/server_test.go \
      fakestorage/bucket_test.go \
      internal/backend/backend_test.go
  '';

  vendorHash = "sha256-n1iu84hQLHzPkb/uQ8yeNIJxtu+65omWIZwJ4Mwirvg=";

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
