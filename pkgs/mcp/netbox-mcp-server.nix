# [netbox-mcp-server](https://github.com/netboxlabs/netbox-mcp-server) provides read-only NetBox access over MCP
{ lib, stdenv, python314, uv-nix }:
let
  name = "netbox-mcp-server";
  version = "1.2.2";
  src = uv-nix.fetchGitHubWorkspace {
    owner = "netboxlabs";
    repo = name;
    rev = "refs/tags/v${version}";
    hash = "sha256-GekuyXOjhmm7FdA2KiHoDvcWXfTXITZBe3sstilgOm4=";
  };
in
(uv-nix.mkEnv {
  inherit name;
  envName = "${name}-${version}";
  python = python314;
  workspaceRoot = src;
  gitignore = false;
  _deps = { netbox-mcp-server = [ ]; };
}).overrideAttrs (_: {
  pname = name;
  inherit version;

  doInstallCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
  installCheckPhase = ''
    runHook preInstallCheck
    export HOME="$TMPDIR/netbox-mcp-install-check"
    mkdir -p "$HOME"
    $out/bin/netbox-mcp-server --help
    runHook postInstallCheck
  '';

  meta = {
    description = "A read-only MCP server for NetBox";
    homepage = "https://github.com/netboxlabs/netbox-mcp-server";
    changelog = "https://github.com/netboxlabs/netbox-mcp-server/releases/tag/v${version}";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = name;
  };
})
