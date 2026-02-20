{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "prom-mcp";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "jpetrucciani";
    repo = "prom-mcp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-LwXmDynV7DB2Zihta/sVGQ9g2318HEjmbP3LDYqAL7s=";
  };

  cargoHash = "sha256-THZHSjr06DgZSbnx1lFCHQbIoUPDqlr9YxOsTzockC0=";

  meta = {
    description = "A prometheus MCP server";
    homepage = "https://github.com/jpetrucciani/prom-mcp";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "prom-mcp";
  };
})
