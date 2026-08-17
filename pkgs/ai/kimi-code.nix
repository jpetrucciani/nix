# [`kimi-code`](https://github.com/MoonshotAI/kimi-code) is an AI coding agent for the terminal
{ lib
, stdenv
, fetchFromGitHub
, fetchPnpmDeps
, pnpmConfigHook
, pnpm_10
, nodejs_24
, makeWrapper
, ripgrep
, fd
, darwin
}:
let
  minNodeVersion = "24.15.0";
  nodejs =
    if lib.versionAtLeast nodejs_24.version minNodeVersion
    then nodejs_24
    else throw "kimi-code requires Node.js >= ${minNodeVersion}, but nodejs_24 is ${nodejs_24.version}";
  pnpm = pnpm_10.override { nodejs-slim = nodejs; };
  nativeTarget =
    if stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isAarch64
    then "linux-arm64"
    else if stdenv.hostPlatform.isLinux
    then "linux-x64"
    else if stdenv.hostPlatform.isDarwin && stdenv.hostPlatform.isAarch64
    then "darwin-arm64"
    else if stdenv.hostPlatform.isDarwin
    then "darwin-x64"
    else throw "kimi-code does not support ${stdenv.hostPlatform.system}";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "kimi-code";
  version = "0.36.1";

  src = fetchFromGitHub {
    owner = "MoonshotAI";
    repo = "kimi-code";
    tag = "@moonshot-ai/kimi-code@${finalAttrs.version}";
    hash = "sha256-EKreZD9zUAEsGXXgdv0S91DsDJN7AtTNzP0Ce8OS1/o=";
  };

  pnpmWorkspaces = [
    "."
    "@moonshot-ai/acp-adapter"
    "@moonshot-ai/acp-server"
    "@moonshot-ai/agent-core"
    "@moonshot-ai/agent-core-v2"
    "@moonshot-ai/kap-server"
    "@moonshot-ai/kaos"
    "@moonshot-ai/kosong"
    "@moonshot-ai/migration-legacy"
    "@moonshot-ai/minidb"
    "@moonshot-ai/kimi-code-sdk"
    "@moonshot-ai/kimi-code-oauth"
    "@moonshot-ai/klient"
    "@moonshot-ai/pi-tui"
    "@moonshot-ai/protocol"
    "@moonshot-ai/kimi-telemetry"
    "@moonshot-ai/transcript"
    "@moonshot-ai/tree-sitter-bash"
    "@moonshot-ai/kimi-code"
    "kimi-code"
    "@moonshot-ai/kimi-inspect"
    "@moonshot-ai/vis"
    "@moonshot-ai/vis-server"
    "@moonshot-ai/vis-web"
    "kimi-code-docs"
  ];

  pnpmDeps = (fetchPnpmDeps.override { inherit pnpm; }) {
    inherit (finalAttrs) pname version src pnpmWorkspaces;
    fetcherVersion = 3;
    hash = "sha256-P450+LKDYkRyk7OZ2mSOX0/RwtbivwR5ZksN8FM6+TU=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm
    (pnpmConfigHook.override { inherit pnpm; })
    makeWrapper
  ] ++ lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.sigtool
  ];

  # The SEA binary embeds offsets into the copied Node executable. Stripping it
  # after injection can invalidate those offsets.
  dontStrip = true;

  buildPhase = ''
    runHook preBuild

    export KIMI_CODE_BUILD_TARGET=${nativeTarget}
    ${lib.optionalString stdenv.hostPlatform.isDarwin ''
      # sigtool can create the ad-hoc signature but cannot inspect it with
      # `codesign -dv`, so leave verification to the upstream release build.
      substituteInPlace apps/kimi-code/scripts/native/build.mjs \
        --replace-fail \
          "await runVerifyStep({ requireGatekeeper: false });" \
          "// runVerifyStep skipped in nix sandbox (sigtool lacks -dv)"
    ''}
    node apps/kimi-code/scripts/check-web-assets.mjs
    pnpm --filter=@moonshot-ai/kimi-code run build:native:sea

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 \
      "apps/kimi-code/dist-native/bin/${nativeTarget}/kimi" \
      "$out/bin/kimi"

    runHook postInstall
  '';

  postInstall = ''
    wrapProgram "$out/bin/kimi" --prefix PATH : ${lib.makeBinPath [ ripgrep fd ]}
  '';

  meta = {
    description = "AI coding agent for the terminal";
    homepage = "https://github.com/MoonshotAI/kimi-code";
    changelog = "https://github.com/MoonshotAI/kimi-code/releases/tag/%40moonshot-ai%2Fkimi-code%40${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "kimi";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };
})
