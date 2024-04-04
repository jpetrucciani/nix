# [uesave](https://github.com/trumank/uesave-rs) is a rust library for reading and writing UE save files
{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage rec {
  pname = "uesave-rs";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "trumank";
    repo = "uesave-rs";
    rev = "v${version}";
    hash = "sha256-YRn14rF94zSTnFAIRuvw84GDRBaqmns9nvaHCTjhWQg=";
  };

  cargoHash = "sha256-MO4LKQbIwiYJzFTMglx4uet8UYtPE+H3MfSEHm0JmOI=";

  meta = with lib; {
    description = "Rust library to read and write Unreal Engine save files";
    homepage = "https://github.com/trumank/uesave-rs";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "uesave-rs";
  };
}
