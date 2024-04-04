# [headscale-ui](https://github.com/gurucomputing/headscale-ui) is a web frontend for headscale management
{ fetchFromGitHub, buildNpmPackage }:
let
  pname = "headscale-ui";
  version = "0.0.1";
  src = fetchFromGitHub {
    owner = "gurucomputing";
    repo = "headscale-ui";
    rev = "63041fd673d81da56e60d2b528a4991981eab746";
    hash = "sha256-pz7oDRfBf/dN+PMEqbMe+es6deQ4QP3pC191ASlyV7U=";
  };
in
buildNpmPackage {
  inherit src version;
  name = pname;
  npmDepsHash = "sha256-MePNbOPSe5wB8/6T3DLs+4+Qlr8f+7cCPs301il7iX8=";
  buildPhase = ''
    runHook preBuild
    mkdir -p $out
    npm run build
    runHook postBuild
  '';
  installPhase = ''
    mv ./build $out/dist
  '';
  makeCacheWritable = true;
  dontFixup = true;
  dontNpmBuild = true;
}
