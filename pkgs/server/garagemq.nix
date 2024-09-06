# [garagemq](https://github.com/valinurovam/garagemq) is an AMQP message broker implemented with golang
{ lib
, stdenv
, buildGoModule
, fetchFromGitHub
, fetchNpmDeps
, npmHooks
, nodejs
}:
let
  pname = "garagemq";
  version = "unstable-2024-05-13";

  src = fetchFromGitHub {
    owner = "valinurovam";
    repo = "garagemq";
    rev = "becd122222a0028eb64343f4d7391ee2ec7a321e";
    hash = "sha256-OPNGTkNenZbzDB7A1y2TWTZbpCNHXIHmTEV/NR/V9J8=";
  };

  ui = stdenv.mkDerivation {
    inherit version;
    pname = "${pname}-ui";
    src = "${src}/admin-frontend";
    npmDeps = fetchNpmDeps {
      src = "${src}/admin-frontend";
      hash = "sha256-5cE/fdEnjwKrEvy+eePSMdeMaFmlpgWAQPfrKRpyiF4=";
    };
    nativeBuildInputs = [
      nodejs
      npmHooks.npmConfigHook
    ];

    buildPhase = ''
      npm run build
    '';

    installPhase = ''
      mv build $out
    '';
  };
in
buildGoModule {
  inherit pname version src;

  vendorHash = "sha256-mstYmmxtQbRgWvN0wk9pPmJEipCh92xNcOvGCs1w0eM=";
  ldflags = [ "-s" "-w" ];

  postInstall = ''
    mkdir -p $out/bin/admin-frontend/build
    cp -a ${ui}/. $out/bin/admin-frontend/build/.
  '';

  meta = {
    description = "AMQP message broker implemented with golang";
    homepage = "https://github.com/valinurovam/garagemq";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "garagemq";
  };
}
