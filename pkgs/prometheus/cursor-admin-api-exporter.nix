# [cursor-admin-api-exporter](https://github.com/matanbaruch/cursor-admin-api-exporter) is a tool for exporting Cursor AI stats
{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "cursor-admin-api-exporter";
  version = "0.1.9";

  src = fetchFromGitHub {
    owner = "matanbaruch";
    repo = "cursor-admin-api-exporter";
    rev = "v${version}";
    hash = "sha256-ey7jQs2HqrWIm3RvJTHOxliPc3q53rLwHh6Wu3psQp4=";
  };

  vendorHash = "sha256-ur49MocizpiIMvhrtUXycPpHsr2JmbHbg9Wo9WBFYGA=";

  env.CGO_ENABLED = 0;

  ldflags = [ "-s" "-w" ];

  meta = {
    description = "Cursor Admin API Exporter - For exporting Cursor AI stats from newly Admin API";
    homepage = "https://github.com/matanbaruch/cursor-admin-api-exporter";
    changelog = "https://github.com/matanbaruch/cursor-admin-api-exporter/blob/${src.rev}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "cursor-admin-api-exporter";
  };
}
