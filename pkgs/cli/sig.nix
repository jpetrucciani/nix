# [sig](https://github.com/ynqa/sig) is an Interactive grep (for streaming)
{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage rec {
  pname = "sig";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "ynqa";
    repo = "sig";
    rev = "v${version}";
    hash = "sha256-KHXBeQFmuA3YO9AN5dkY/fl/z2RdbR6AqSSEGUNrxt4=";
  };

  cargoHash = "sha256-seH+ypDSoRUf/+bmVLICEVwXNk7gGZwQ7R84Xu0XjNw=";

  meta = with lib; {
    description = "Interactive grep (for streaming";
    homepage = "https://github.com/ynqa/sig";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "sig";
  };
}
