# [headscale-ui](https://github.com/gurucomputing/headscale-ui) is a web frontend for headscale management
{ lib
, stdenvNoCC
, fetchurl
, unzip
, mkGitHubReleaseUpdater
}:
let
  release = lib.importJSON ./headscale-ui.json;
  artifact = release.artifacts.universal;
  inherit (release) version;
in
stdenvNoCC.mkDerivation {
  pname = "headscale-ui";
  inherit version;

  src = fetchurl {
    url = "https://github.com/gurucomputing/headscale-ui/releases/download/${version}/${artifact.name}";
    inherit (artifact) sha256;
  };

  strictDeps = true;
  nativeBuildInputs = [ unzip ];

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/dist"
    unzip -q "$src" -d "$out/dist"
    test -f "$out/dist/web/index.html"

    runHook postInstall
  '';

  passthru.updateScript = mkGitHubReleaseUpdater {
    pname = "headscale-ui";
    owner = "gurucomputing";
    repo = "headscale-ui";
    dataFile = "pkgs/cloud/headscale-ui.json";
    tagPrefix = "";
    assets.universal = "headscale-ui.zip";
  };

  meta = {
    description = "Web frontend for Headscale management";
    homepage = "https://github.com/gurucomputing/headscale-ui";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    platforms = lib.platforms.all;
  };
}
