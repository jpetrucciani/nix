{ lib
, rustPlatform
, fetchFromGitHub
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "nvme-exporter";
  version = "0.0.2";

  src = fetchFromGitHub {
    owner = "jpetrucciani";
    repo = "nvme-exporter";
    tag = "v${finalAttrs.version}";
    hash = "sha256-cbq+Qi1xGsUbwUGrqDjGXSEN8VNrkeBNEJcYouVqSNs=";
  };

  cargoHash = "sha256-G40RJ8dcc8AjYcEh0+qDsetUiBzeLNlQK/xILkLmxzs=";

  meta = {
    description = "A lightweight nvme stats exporter";
    homepage = "https://github.com/jpetrucciani/nvme-exporter";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "nvme-exporter";
  };
})
