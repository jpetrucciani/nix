# [mcpo](https://github.com/open-webui/mcpo) is a simple, secure MCP-to-OpenAPI proxy server
{ stdenvNoCC, lib, python313, rsync, uv-nix }:
let
  name = "mcpo";
  version = "0.0.13";

  src = uv-nix.fetchGitHubWorkspace {
    owner = "open-webui";
    repo = name;
    rev = "refs/tags/v${version}";
    hash = "sha256-4VkOaR2nW6HTfxF24xiH9wC7r277XsSN12+W0759Fmg=";
  };
  uvEnv = uv-nix.mkEnv {
    inherit name;
    gitignore = false;
    python = python313;
    workspaceRoot = src;
    pyprojectOverrides = final: prev: { };
  };
in
stdenvNoCC.mkDerivation {
  inherit version src;
  pname = name;
  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    ${rsync}/bin/rsync -a --exclude='bin/' ${uvEnv}/ $out
    cp ${uvEnv}/bin/mcpo $out/bin/mcpo
    runHook postInstall
  '';
  meta = {
    changelog = "https://github.com/open-webui/mcpo/blob/main/CHANGELOG.md";
    description = "A simple, secure MCP-to-OpenAPI proxy server";
    homepage = "https://github.com/open-webui/mcpo";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "mcpo";
  };
}
