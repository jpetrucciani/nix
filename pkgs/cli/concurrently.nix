{ lib
, stdenv
, fetchFromGitHub
, makeWrapper
, nodejs
, pnpm_8
, fetchPnpmDeps
, pnpmConfigHook
}:
let
  pnpm = pnpm_8;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "concurrently";
  version = "9.2.0";

  src = fetchFromGitHub {
    owner = "open-cli-tools";
    repo = "concurrently";
    rev = "refs/tags/v${finalAttrs.version}";
    hash = "sha256-voPL3qw7oWJP1NqGgkYGCFZ/RhBdBitp4Y1LXSuaeEo=";
  };

  pnpmDeps = (fetchPnpmDeps.override { inherit pnpm; }) {
    inherit (finalAttrs) pname version src;
    hash = "sha256-q+EBUEODZvjsLAHfAN/EaANICjbmTl1x6OPedrSGRnk=";
    fetcherVersion = 2;
  };

  nativeBuildInputs = [
    makeWrapper
    nodejs
    pnpm
    (pnpmConfigHook.override { inherit pnpm; })
  ];

  buildPhase = ''
    runHook preBuild

    pnpm build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/lib/concurrently"
    cp -r dist node_modules "$out/lib/concurrently"
    makeWrapper "${lib.getExe nodejs}" "$out/bin/concurrently" \
      --add-flags "$out/lib/concurrently/dist/bin/concurrently.js"
    ln -s "$out/bin/concurrently" "$out/bin/con"

    runHook postInstall
  '';

  meta = {
    changelog = "https://github.com/open-cli-tools/concurrently/releases/tag/v${finalAttrs.version}";
    description = "Run commands concurrently";
    homepage = "https://github.com/open-cli-tools/concurrently";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "concurrently";
  };
})
