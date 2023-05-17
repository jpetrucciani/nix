{ fetchFromGitHub, buildNpmPackage, bash, nodejs_20, python310, llama-cpp }:
let
  src = fetchFromGitHub {
    owner = "keldenl";
    repo = "gpt-llama.cpp";
    rev = "334ef17887040d0e56fb1caf7cb783d6fc693e44";
    hash = "sha256-GoMS37nPXrBdXVPyzaE7iuOinYeE3UrmOPoD2ZXReL4=";
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
  version = "0.2.6";

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

  npmDepsHash = "sha256-IvCplh704Bdma5c5NTy6dvQmf2p6vZuIua0oZ7YskEU=";

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
