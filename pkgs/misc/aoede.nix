{ lib
, rustPlatform
, fetchFromGitHub
, fetchpatch
, cmake
, pkg-config
, libopus
, stdenv
, darwin
}:

rustPlatform.buildRustPackage rec {
  pname = "aoede";
  version = "0.7.0";

  src = fetchFromGitHub {
    owner = "codetheweb";
    repo = "aoede";
    rev = "v${version}";
    hash = "sha256-Kjbf55ufZyRXAS3ExLfqkmSYw2R0Acc25867MNWIB/0=";
  };

  cargoHash = "sha256-MgBgQ/641wf3SnOB2lNYluI2udgfhqrD/4c6EFtZv9I=";

  patches = [
    # fix cargo lock file
    (fetchpatch {
      url = "https://github.com/jpetrucciani/aoede/commit/dc7e4bbc630e1242d84b00df84606434aee6e4e9.patch";
      sha256 = "sha256-SmHq1ykKE3a1vtV1Oa5CmyMXEHNO2cAb46XiXNbPUb4=";
    })
  ];

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    libopus
  ] ++ (lib.optionals stdenv.isDarwin [
    darwin.apple_sdk.frameworks.Security
  ]);

  meta = with lib; {
    description = "A self-hosted Spotify → Discord music bot";
    homepage = "https://github.com/codetheweb/aoede";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "aoede";
  };
}
