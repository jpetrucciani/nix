{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "fake-gcs-server";
  version = "1.47.4";

  src = fetchFromGitHub {
    owner = "fsouza";
    repo = "fake-gcs-server";
    rev = "v${version}";
    hash = "sha256-DnoMtkDffRza1LAVrkuwyO18IutTPY/YG00uv/EAZqU=";
  };

  postPatch = ''
    sed -i -E 's#"/var/tmp"#os.TempDir()#g' \
      internal/grpc/server_test.go \
      fakestorage/bucket_test.go \
      internal/backend/backend_test.go
  '';

  vendorHash = "sha256-wbPtMtKQAyz+tz2OdI9ynZUMLcDI2g3+QsiC6pO8Src=";

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
