{ lib
, stdenv
, stdenvNoCC
, fetchurl
, autoPatchelfHook
, darwin
, mkGitHubReleaseUpdater
}:
let
  release = lib.importJSON ./obscura.json;
  artifact = release.artifacts.${stdenvNoCC.hostPlatform.system}
    or (throw "obscura: unsupported system ${stdenvNoCC.hostPlatform.system}");
  inherit (release) version;
in
stdenvNoCC.mkDerivation {
  pname = "obscura";
  inherit version;

  src = fetchurl {
    url = "https://github.com/h4ckf0r0day/obscura/releases/download/v${version}/${artifact.name}";
    inherit (artifact) sha256;
  };

  strictDeps = true;
  nativeBuildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [
    autoPatchelfHook
  ] ++ lib.optionals stdenvNoCC.hostPlatform.isDarwin [
    darwin.autoSignDarwinBinariesHook
  ];
  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ stdenv.cc.cc.lib ];

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    tar -xzf "$src"
    install -Dm755 obscura obscura-worker -t "$out/bin"

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    test -x "$out/bin/obscura-worker"
    "$out/bin/obscura" --version | grep -F "obscura ${version}"
    runHook postInstallCheck
  '';

  passthru.updateScript = mkGitHubReleaseUpdater {
    pname = "obscura";
    owner = "h4ckf0r0day";
    repo = "obscura";
    dataFile = "pkgs/server/obscura.json";
    assets = {
      aarch64-darwin = "obscura-aarch64-macos.tar.gz";
      aarch64-linux = "obscura-aarch64-linux.tar.gz";
      x86_64-linux = "obscura-x86_64-linux.tar.gz";
    };
  };

  meta = {
    description = "Headless browser for AI agents and web scraping";
    homepage = "https://github.com/h4ckf0r0day/obscura";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "obscura";
    platforms = builtins.attrNames release.artifacts;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
