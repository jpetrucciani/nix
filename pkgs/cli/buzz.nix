# Buzz's sprig multicall binary provides the ACP harness, agent, MCP server, and CLI.
{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, openssl
, protobuf
, cmake
, perl
, git
}:
rustPlatform.buildRustPackage {
  pname = "buzz";
  version = "0.1.0-unstable-2026-09-30";

  src = fetchFromGitHub {
    owner = "block";
    repo = "buzz";
    rev = "2664d14316790a57ea44b3f97c57440b70e43436";
    hash = "sha256-28hY8dkwutFP2HrWkOQF3P1znfYBx+tPfOccnP14tm8=";
  };

  cargoHash = "sha256-A/lpudjM3ZahSNiWHxW8UKFlBhdBuAEQL87c8Q+C7Q4=";
  cargoBuildFlags = [ "-p" "sprig" ];

  nativeBuildInputs = [ pkg-config protobuf cmake perl git ];
  buildInputs = [ openssl ];
  env = {
    OPENSSL_NO_VENDOR = "1";
    CMAKE_POLICY_VERSION_MINIMUM = "3.5";
  };

  # The workspace integration tests require external services.
  doCheck = false;

  # Keep upstream's multicall name; use real ripgrep/tree packages for those commands.
  postInstall = ''
    for name in buzz-acp buzz-agent buzz-dev-mcp buzz git-credential-nostr git-sign-nostr; do
      ln -s sprig "$out/bin/$name"
    done
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/sprig" --version
    "$out/bin/buzz-acp" --help > /dev/null
    "$out/bin/buzz" --help > /dev/null
    runHook postInstallCheck
  '';

  meta = {
    description = "Buzz ACP harness, agent, developer MCP server, and CLI";
    homepage = "https://github.com/block/buzz";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "buzz";
    platforms = lib.platforms.unix;
  };
}
