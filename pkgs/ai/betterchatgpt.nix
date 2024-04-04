# [`BetterChatGPT`](https://github.com/ztjhz/BetterChatGPT) is an alternative UI for OpenAI's ChatGPT.
{ fetchFromGitHub, mkYarnPackage, cname ? "meme.com" }:
let
  pname = "BetterChatGPT";
  version = "0.1.0";
  src = fetchFromGitHub {
    owner = "ztjhz";
    repo = "BetterChatGPT";
    rev = "52fa56c1daad158677d03f533536c2404cca7ad2";
    hash = "sha256-FIXm4j8m/K5MYU/UPJerhcczAoEclWiA142h3lIdwG0=";
  };
in
mkYarnPackage {
  inherit src version;
  name = pname;
  preBuild = ''
    
  '';
  buildPhase = ''
    runHook preBuild
    pushd ./deps/better-chatgpt
    yarn --offline run build
    popd
    runHook postBuild
  '';
  distPhase = ''
    mkdir -p $out
    cp -r ./deps/better-chatgpt/dist/* $out
    echo "${cname}" >$out/CNAME
  '';
  dontFixup = true;
  dontInstall = true;
}
