final: prev:
with prev;
let
  inherit (stdenv) isLinux isDarwin isAarch64;
  isM1 = isDarwin && isAarch64;
in
rec {
  json-crack = prev.callPackage
    ({ stdenvNoCC, fetchFromGitHub, mkYarnPackage, nodejs ? nodejs-18_x }:
      let
        pname = "jsoncrack";
        version = "2.5.0";

        src = fetchFromGitHub {
          owner = "AykutSarac";
          repo = "jsoncrack.com";
          rev = "v${version}";
          sha256 = "sha256-RWrvKeYBjSNfEfcu/nYhvL4w4yVCKjr0ZZaZCeuIWvc=";
        };
        yarn = mkYarnPackage {
          inherit src;
          pname = "jsoncrack";
          buildPhase = ''
            runHook preBuild
            
            pushd ./deps/json-crack/
            mv node_modules node_modules.bak
            cp -r $(readlink -f node_modules.bak) node_modules
            chmod +w node_modules
            yarn --offline run build
            popd

            runHook postBuild
          '';

          distPhase = ''
            mkdir -p $out
            cp -r ./deps/json-crack/out/* $out
          '';

          dontFixup = true;
          dontInstall = true;
        };
      in
      yarn
    )
    { };
}
