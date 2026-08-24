# [pogocache](https://github.com/tidwall/pogocache) is fast caching software focused on low latency and CPU efficiency
{ lib
, stdenvNoCC
, fetchurl
, mkGitHubReleaseUpdater
}:
let
  release = lib.importJSON ./pogocache.json;
  artifact = release.artifacts.${stdenvNoCC.hostPlatform.system}
    or (throw "pogocache: unsupported system ${stdenvNoCC.hostPlatform.system}");
  archiveRoot = lib.removeSuffix ".tar.gz" artifact.name;
  inherit (release) version;
in
stdenvNoCC.mkDerivation {
  pname = "pogocache";
  inherit version;

  src = fetchurl {
    url = "https://github.com/tidwall/pogocache/releases/download/${version}/${artifact.name}";
    inherit (artifact) sha256;
  };

  strictDeps = true;
  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    tar -xzf "$src"
    install -Dm755 "${archiveRoot}/pogocache" "$out/bin/pogocache"
    install -Dm644 "${archiveRoot}/LICENSE" "$out/share/licenses/pogocache/LICENSE"

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/pogocache" --version | grep -F "pogocache ${version}"
    runHook postInstallCheck
  '';

  passthru.updateScript = mkGitHubReleaseUpdater {
    pname = "pogocache";
    owner = "tidwall";
    repo = "pogocache";
    dataFile = "pkgs/server/pogocache.json";
    tagPrefix = "";
    assets = {
      aarch64-darwin = "pogocache-apple-arm64.tar.gz";
      aarch64-linux = "pogocache-linux-arm64-musl.tar.gz";
      x86_64-linux = "pogocache-linux-amd64-musl.tar.gz";
    };
  };

  meta = {
    description = "Fast caching software focused on low latency and CPU efficiency";
    homepage = "https://github.com/tidwall/pogocache";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "pogocache";
    platforms = builtins.attrNames release.artifacts;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
