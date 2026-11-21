# [jet](https://github.com/jpetrucciani/jet) is a native terminal on libghostty-vt, from its release archives.
# `-terminal` because nixpkgs' `jet` is borkdude's JSON/EDN tool, as with `blackbox-terminal`; the program is `jet`.
{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, unzip
, alsa-lib
, libGL
, libx11
, libxcb
, libxcursor
, libxi
, libxkbcommon
, vulkan-loader
, wayland
, mkGitHubReleaseUpdater
}:
let
  release = lib.importJSON ./jet-terminal.json;
  inherit (stdenv.hostPlatform) isDarwin system;
  artifact = release.artifacts.${system} or (throw "jet-terminal: unsupported system ${system}");
  inherit (release) version;
in
stdenv.mkDerivation {
  pname = "jet-terminal";
  inherit version;

  src = fetchurl {
    url = "https://github.com/jpetrucciani/jet/releases/download/v${version}/${artifact.name}";
    inherit (artifact) sha256;
  };

  strictDeps = true;
  nativeBuildInputs = if isDarwin then [ unzip ] else [ autoPatchelfHook ];
  buildInputs = lib.optionals (!isDarwin) [ stdenv.cc.cc.lib ];
  # jet links only libc; it dlopens the rest. On its RUNPATH rather than
  # LD_LIBRARY_PATH, which every shell it starts would inherit.
  runtimeDependencies = lib.optionals (!isDarwin) [
    alsa-lib # bell and notification sounds
    libGL
    libx11
    libxcb
    libxcursor
    libxi
    libxkbcommon
    vulkan-loader
    wayland
  ];

  sourceRoot = ".";
  dontConfigure = true;
  dontBuild = true;
  # the macOS app is signed; leave it as it shipped
  dontFixup = isDarwin;

  installPhase = ''
    runHook preInstall
  '' + (if isDarwin then ''
    mkdir -p "$out/Applications" "$out/bin"
    cp -R jet.app "$out/Applications/"
    ln -s "$out/Applications/jet.app/Contents/MacOS/jet" "$out/bin/jet"
    ln -s "$out/Applications/jet.app/Contents/MacOS/jet-cli" "$out/bin/jet-cli"
    install -Dm644 LICENSE THIRD-PARTY-NOTICES -t "$out/share/doc/jet"
  '' else ''
    cd jet-${version}-linux-x86_64
    install -Dm755 jet jet-cli -t "$out/bin"
    install -Dm644 LICENSE THIRD-PARTY-NOTICES -t "$out/share/doc/jet"
  '') + ''
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/jet-cli" --version | grep -Fx "jet-cli ${version}"
    runHook postInstallCheck
  '';

  passthru.updateScript = mkGitHubReleaseUpdater {
    pname = "jet-terminal";
    owner = "jpetrucciani";
    repo = "jet";
    dataFile = "pkgs/cli/jet-terminal.json";
    assets = {
      aarch64-darwin = "jet-{version}-macos-arm64.zip";
      x86_64-linux = "jet-{version}-linux-x86_64.tar.gz";
    };
  };

  meta = {
    description = "Fast native terminal on libghostty-vt, with tabs, splits, a quake window and jetmux sessions as native tabs";
    homepage = "https://github.com/jpetrucciani/jet";
    changelog = "https://github.com/jpetrucciani/jet/blob/main/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "jet";
    platforms = builtins.attrNames release.artifacts;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
