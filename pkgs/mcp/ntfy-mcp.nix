{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "ntfy-mcp";
  version = "0.0.2";

  src = fetchFromGitHub {
    owner = "jpetrucciani";
    repo = "ntfy-mcp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-LfseChzWPl09/dsR1W8ywP+plztsV8nEI1z0gxNX5ZU=";
  };

  cargoHash = "sha256-9yP3EUvR8ALIafkeyh5pmOfEhiTQb5d8+jy2HPti1FQ=";

  meta = {
    description = "A quick and lightweight MCP server for ntfy";
    homepage = "https://github.com/jpetrucciani/ntfy-mcp";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "ntfy-mcp";
  };
})
