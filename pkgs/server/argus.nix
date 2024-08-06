# [argus](https://github.com/jpetrucciani/argus) is a customizable http request logger with prometheus metrics 
{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage rec {
  pname = "argus";
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "jpetrucciani";
    repo = "argus";
    rev = version;
    hash = "sha256-1ZSo1Nv6WeEI/5uNhvzwB2CudqHf/YKRiCAhOR9ARgg=";
  };

  cargoHash = "sha256-q8a7HXhE46OAsh1QceLQNMUadjm1GIrnQwZYsa96D+M=";

  meta = with lib; {
    description = "A customizable http request logger with prometheus metrics";
    homepage = "https://github.com/jpetrucciani/argus";
    license = licenses.mit;
    maintainers = with maintainers; [ jpetrucciani ];
    mainProgram = "argus";
  };
}
