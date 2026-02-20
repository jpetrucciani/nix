{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "loki-mcp";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "jpetrucciani";
    repo = "loki-mcp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-mhSQl1BzEtplqBCB/6eYyiUjPY7A3LprNZ9c0/tCqoI=";
  };

  cargoHash = "sha256-HM/tWTA9wZNI8dJ+uEHFAIF8M+QVFmyqhJmbBFFWFRg=";

  meta = {
    description = "A loki MCP server";
    homepage = "https://github.com/jpetrucciani/loki-mcp";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "loki-mcp";
  };
})
