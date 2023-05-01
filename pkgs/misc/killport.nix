{ lib, stdenv, runCommand, darwin, fetchFromGitHub, rustPlatform }:
let
  pname = "killport";
  version = "0.6.0";
in
rustPlatform.buildRustPackage rec {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "jkfran";
    repo = pname;
    # rev = "v${version}";
    rev = "b9346e790e447b2f6719ee7a136d37a460a4f9f4";
    sha256 = "sha256-Kj1GsZiwkdKu8oP2fPjSic5uYN496/3FXALZxZz+9eg=";
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

  cargoHash = "sha256-sdQduuapF7ZuTCGqrt4swpM9IWnd8EmKptrr+1QEye4=";

  meta = with lib; {
    description = "Easily kill processes running on a specified port";
    homepage = "https://github.com/jkfran/killport";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
  };
}
