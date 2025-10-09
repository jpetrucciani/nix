# experimental webapps
final: prev:
{
  json-crack = final.callPackage
    ({ fetchFromGitHub, mkYarnPackage }:
      let
        version = "2.6.0";

        src = fetchFromGitHub {
          owner = "AykutSarac";
          repo = "jsoncrack.com";
          rev = "v${version}";
          hash = "sha256-Jmpv/PvWLkMUjRTKRiJwW/OmNVgPlfu/dG9qeCAykRM=";
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
            mv $out/editor.html $out/index.html
            rm $out/CNAME
          '';

          dontFixup = true;
          dontInstall = true;
        };
      in
      yarn
    )
    { };
}
