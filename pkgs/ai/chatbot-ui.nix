# [`chatbot-ui`](https://github.com/mckaywrigley/chatbot-ui) is a popular frontend for OpenAI compliant APIs. It is designed to look similar to OpenAI's ChatGPT UI.
{ fetchFromGitHub, buildNpmPackage, fetchpatch, bash }:
let
  src = fetchFromGitHub {
    owner = "mckaywrigley";
    repo = "chatbot-ui";
    rev = "fa3f6e93bbe0d1ff9f208ddefae6fc7dfb738dc7";
    hash = "sha256-Lzk8xBEo/kIZAvAQNWOjbGvNsnnyYy704w4bt29gLbg=";
  };
in
buildNpmPackage rec {
  inherit src;
  pname = "chatbot-ui";
  version = "0.1.0";

  dontNpmBuild = true;
  NODE_OPTIONS = "--openssl-legacy-provider";
  npmDepsHash = "sha256-7mReAoIQcIk+n6UDYtLLlTyuT2F11jY9rvwJiykouVw=";

  patches = [
    (fetchpatch {
      url = "https://github.com/jpetrucciani/chatbot-ui/commit/239219e0a4f6743e18fc2cdf6034ebc638eb7464.patch";
      sha256 = "sha256-cWQcTmQRZ7P6xhBqkZyyivup70QLLghvzL2dv+aY0+8=";
    })
  ];

  OPENAI_API_HOST = "http://localhost:8420";
  OPENAI_API_TYPE = "openai";
  OPENAI_API_VERSION = "2023-05-15";
  OPENAI_ORGANIZATION = "";
  AZURE_DEPLOYMENT_ID = "gpt-4";

  buildPhase = ''
    runHook preBuild
    rm Makefile
    # remove issue with google fonts
    sed -i -E  -e '/next\/font\/google/d' -e '/const inter/d' ./pages/_app.tsx
    substituteInPlace ./pages/_app.tsx --replace "className={inter.className}" ""
    npm --offline run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/app
    cp -r ./node_modules $out/app/node_modules
    cp -r ./.next $out/app/.next
    cp -r ./public $out/app/public
    cp ./package*.json $out/app/.
    cp ./next.config.js $out/app/next.config.js
    cp ./next-i18next.config.js $out/app/next-i18next.config.js
    cat <<EOF >$out/bin/chatbot-ui
    #!${bash}/bin/bash
    export PORT="\''${PORT:-8421}"
    export DEFAULT_SYSTEM_PROMPT="\''${DEFAULT_SYSTEM_PROMPT:-You are ChatGPT, a large language model trained by OpenAI. Follow the user\'s instructions carefully. Respond using markdown.}"
    export OPENAI_API_HOST="\''${OPENAI_API_HOST:-${OPENAI_API_HOST}}"
    export OPENAI_API_TYPE="\''${OPENAI_API_TYPE:-${OPENAI_API_TYPE}}"
    export OPENAI_API_VERSION="\''${OPENAI_API_VERSION:-${OPENAI_API_VERSION}}"
    export OPENAI_ORGANIZATION="\''${OPENAI_ORGANIZATION:-${OPENAI_ORGANIZATION}}"
    export AZURE_DEPLOYMENT_ID="\''${AZURE_DEPLOYMENT_ID:-${AZURE_DEPLOYMENT_ID}}"
    cd $out/app
    ./node_modules/.bin/next start "\$@"
    EOF
    chmod +x $out/bin/chatbot-ui
    runHook postInstall
  '';
}
