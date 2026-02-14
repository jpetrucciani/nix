# [fake-gcs-server](https://github.com/fsouza/fake-gcs-server) is a google cloud storage emulator
{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "fake-gcs-server";
  version = "1.54.0";

  src = fetchFromGitHub {
    owner = "fsouza";
    repo = "fake-gcs-server";
    rev = "v${version}";
    hash = "sha256-mskNNTytnqqFXP4REMz7KLgWL0ma/8hlQKSAABOGuvk=";
  };

  doCheck = false;

  postPatch = ''
    sed -i -E 's#"/var/tmp"#os.TempDir()#g' \
      internal/grpc/server_test.go \
      fakestorage/bucket_test.go \
      internal/backend/backend_test.go
  '';

  vendorHash = "sha256-KNappojVBU1F9F3FqindXVDzOIy7IwYd7xVzbqQk6QE=";

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
