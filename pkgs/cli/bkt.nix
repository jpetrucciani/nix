# [bkt](https://github.com/dimo414/bkt) is a subprocess caching utility
{ lib, fetchFromGitHub, rustPlatform, nix-update-script }:
let
  pname = "bkt";
  version = "0.8.2";
in
rustPlatform.buildRustPackage rec {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "dimo414";
    repo = "bkt";
    rev = version;
    sha256 = "sha256-qb7uRvCAXCayDIg8yQfF/Yxe0pNvR3giCQYmMIur2rM=";
  };

  cargoHash = "sha256-locf3k0jIT9RNQS9yCUtOpj4oKo5pOBU3CEYAJDbaPU=";

  checkFlags = [
    # The test shells out to sudo, which is intentionally absent from the sandbox.
    "--skip=cli::cache_dirs_multi_user"
    # The test observes a command side effect before the detached refresh writes its cache entry.
    "--skip=cli::cache_refreshes_in_background"
  ];

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "subprocess caching utility";
    homepage = "https://github.com/dimo414/bkt";
    license = licenses.mit;
    mainProgram = "bkt";
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
