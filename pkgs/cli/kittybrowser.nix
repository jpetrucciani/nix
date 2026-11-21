{ lib
, stdenv
, fetchFromGitHub
, rustPlatform
, makeWrapper
, chromium
}:
let
  defaultBrowser =
    if stdenv.hostPlatform.isDarwin
    then "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    else lib.getExe chromium;
in
rustPlatform.buildRustPackage {
  pname = "kittybrowser";
  version = "0.1.0-unstable-2026-11-16";

  src = fetchFromGitHub {
    owner = "graiz";
    repo = "KittyBrowser";
    rev = "d252d5fe771f4d8f18fbf184d8239524b3ecda39";
    hash = "sha256-GXEWnCBDTPCCoD1RD+7qxyQCFJvKWBcFQ1CRBTPmcsA=";
  };

  cargoHash = "sha256-eBaeoChVTfIfmEem1gSCBxMMU/IJw7wOfWdOU2/9d6o=";

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram "$out/bin/kb" \
      --set-default KB_CHROME ${lib.escapeShellArg defaultBrowser}
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/kb" --version
    runHook postInstallCheck
  '';

  meta = {
    description = "Terminal web browser that renders headless Chrome with the kitty graphics protocol";
    homepage = "https://github.com/graiz/KittyBrowser";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.jpetrucciani ];
    mainProgram = "kb";
    platforms = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
  };
}
