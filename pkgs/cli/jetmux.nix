# [jetmux](https://github.com/jpetrucciani/jet) is jet's multiplexer: a daemon that owns the shells, with a terminal
# client, a web client and companions. From its release binaries: static for Linux, Apple silicon for macOS.
{ lib
, stdenvNoCC
, fetchurl
, mkGitHubReleaseUpdater
}:
let
  release = lib.importJSON ./jetmux.json;
  inherit (stdenvNoCC.hostPlatform) isDarwin system;
  artifact = release.artifacts.${system} or (throw "jetmux: unsupported system ${system}");
  inherit (release) version;
in
stdenvNoCC.mkDerivation {
  pname = "jetmux";
  inherit version;

  src = fetchurl {
    url = "https://github.com/jpetrucciani/jet/releases/download/v${version}/${artifact.name}";
    inherit (artifact) sha256;
  };

  strictDeps = true;
  sourceRoot = lib.removeSuffix ".tar.gz" artifact.name;
  dontConfigure = true;
  dontBuild = true;
  # the macOS binaries carry the linker's signature; leave them as shipped
  dontFixup = isDarwin;

  installPhase = ''
    runHook preInstall
    install -Dm755 jetmux jetmux-mcp jetmux-notify jetmux-rec jetmux-web -t "$out/bin"
    install -Dm644 LICENSE THIRD-PARTY-NOTICES jetmux.toml -t "$out/share/doc/jetmux"
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    for exe in "$out"/bin/*; do
      "$exe" --version | grep -Fx "$(basename "$exe") ${version}"
    done
    runHook postInstallCheck
  '';

  passthru.updateScript = mkGitHubReleaseUpdater {
    pname = "jetmux";
    owner = "jpetrucciani";
    repo = "jet";
    dataFile = "pkgs/cli/jetmux.json";
    assets = {
      aarch64-darwin = "jetmux-{version}-macos-arm64.tar.gz";
      aarch64-linux = "jetmux-{version}-linux-aarch64.tar.gz";
      x86_64-linux = "jetmux-{version}-linux-x86_64.tar.gz";
    };
  };

  meta = {
    description = "Multiplexer whose sessions outlive any client, shown by jet as native tabs and splits";
    homepage = "https://github.com/jpetrucciani/jet";
    changelog = "https://github.com/jpetrucciani/jet/blob/main/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "jetmux";
    platforms = builtins.attrNames release.artifacts;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
