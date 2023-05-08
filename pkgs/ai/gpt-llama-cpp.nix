{ fetchFromGitHub, buildNpmPackage, bash, nodejs_18, python310, llama-cpp }:
let
  src = fetchFromGitHub {
    owner = "keldenl";
    repo = "gpt-llama.cpp";
    rev = "86f0f0ea5bb44e0044e716fafc26dacc42e8ad7a";
    hash = "sha256-PCG27PxJUAWZw2mqFCpxGC6F7kxMx+ObLE1VeNe3l7c=";
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
  version = "0.2.3";

  postPatch = ''
    sed -i -E 's#("postinstall": )(.*)#\1"true"#g' ./package.json
    substituteInPlace ./routes/chatRoutes.js --replace "'main'" "'llama'"
    substituteInPlace ./routes/completionsRoutes.js --replace "'main'" "'llama'"
    substituteInPlace ./utils.js --replace "join(path, 'llama.cpp')" "'${llama-cpp}/bin'"
  '';

  dontNpmBuild = true;
  NODE_OPTIONS = "--openssl-legacy-provider";

  nativeBuildInputs = [ python ];
  propagatedBuildInputs = [ python llama-cpp ];

  npmDepsHash = "sha256-JhZLxZvHdf1ojE2A3hNureBLCOaYP4ajHdYu+lmV998=";

  postInstall = ''
    cat <<EOF >$out/bin/gpt-llama-cpp
    #!${bash}/bin/bash
    export PORT="\''${PORT:-8420}"
    cd $out/lib/node_modules/gpt-llama.cpp
    ${nodejs_18}/bin/node ./index.js "\$@"
    EOF
    chmod +x $out/bin/gpt-llama-cpp
  '';
}
