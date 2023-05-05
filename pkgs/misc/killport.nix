{ lib, stdenv, runCommand, darwin, fetchFromGitHub, rustPlatform }:
let
  pname = "killport";
  version = "0.8.0";
in
rustPlatform.buildRustPackage rec {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "jkfran";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-dpFHwo6fcV2BT96oBQjjuU6JfxSpzuyAC4QLoo5Uqzw=";
  };

  buildInputs = lib.optional (stdenv.isDarwin && !stdenv.isAarch64) (
    # Pull a header that contains a definition of proc_pid_rusage().
    # (We pick just that one because using the other headers from `sdk` is not
    # compatible with our C++ standard library. This header is already in
    # the standard library on aarch64)
    runCommand "webkitgtk_headers" { } ''
      install -Dm444 "${lib.getDev darwin.apple_sdk.sdk}"/include/libproc.h "$out"/include/libproc.h
    ''
  );

  cargoHash = "sha256-WKjCB9/CFd1sIB5vRdETcgaMHS7VwyMUyFIjujOxz88=";

  meta = with lib; {
    description = "Easily kill processes running on a specified port";
    homepage = "https://github.com/jkfran/killport";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
