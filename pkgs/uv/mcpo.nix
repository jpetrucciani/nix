# [mcpo](https://github.com/open-webui/mcpo) is a simple, secure MCP-to-OpenAPI proxy server
{ stdenv, lib, fetchFromGitHub, python ? python312, python312, rsync, uv-nix }:
let
  name = "mcpo";
  version = "0.0.12";

  src = fetchFromGitHub {
    owner = "open-webui";
    repo = "mcpo";
    rev = "refs/tags/v${version}";
    hash = "sha256-biLfXQ/4YvbQaL/3YLXFu+31wLwe25JIaCZJ0DMgPCY=";
  };
  uvEnv = uv-nix.mkEnv {
    inherit name python;
    workspaceRoot = src;
    pyprojectOverrides = final: prev: { };
  };
in
stdenv.mkDerivation {
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
    description = "A simple, secure MCP-to-OpenAPI proxy server ";
    homepage = "https://github.com/open-webui/mcpo";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "mcpo";
  };
}
