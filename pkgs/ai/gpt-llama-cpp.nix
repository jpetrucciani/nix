{ fetchFromGitHub, buildNpmPackage, bash, nodejs_20, python310, llama-cpp }:
let
  src = fetchFromGitHub {
    owner = "keldenl";
    repo = "gpt-llama.cpp";
    rev = "4781f29aa842b238388c962609ef574ff40a2855";
    hash = "sha256-sx5XiabkJ1/CgQZLbLSAGw5Qe1f1ZUWVnKYPbDXa2hA=";
  };
  python = python310.withPackages (p: with p; [
    numpy
    sentence-transformers
    sentencepiece
  ]);
in
buildNpmPackage {
  inherit src;
  pname = "gpt-llama-cpp";
  version = "0.2.5";

  postPatch = ''
    sed -i -E 's#("postinstall": )(.*)#\1"true",#g' ./package.json
    substituteInPlace ./routes/chatRoutes.js --replace "'main'" "'llama'"
    substituteInPlace ./routes/completionsRoutes.js --replace "'main'" "'llama'"
    substituteInPlace ./utils.js --replace "join(path, 'llama.cpp')" "'${llama-cpp}/bin'"
  '';

  nodejs = nodejs_20;
  dontNpmBuild = true;
  NODE_OPTIONS = "--openssl-legacy-provider";

  nativeBuildInputs = [ python ];
  propagatedBuildInputs = [ python llama-cpp ];

  npmDepsHash = "sha256-iO4h4iqPV96xz3fcxxO0ivMY/ipCUJMhtTPYC3I2x9g=";

  postInstall = ''
    cat <<EOF >$out/bin/gpt-llama-cpp
    #!${bash}/bin/bash
    export PORT="\''${PORT:-8420}"
    cd $out/lib/node_modules/gpt-llama.cpp
    ${nodejs_20}/bin/node ./index.js "\$@"
    EOF
    chmod +x $out/bin/gpt-llama-cpp
  '';
}
