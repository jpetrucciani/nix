{ lib
, rustPlatform
, fetchFromGitHub
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "aq";
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "jpetrucciani";
    repo = "aq";
    tag = "v${finalAttrs.version}";
    hash = "sha256-aQblBJ0j28hJzz3g/QatacKLhM4KjIhIWnizjJjCx8w=";
  };

  cargoHash = "sha256-M90pXHwujmsplZ1qq83KW+a9VDvSY4IVfoUAs/CjoTo=";

  meta = {
    description = "Multi-format data processing tool";
    homepage = "https://github.com/jpetrucciani/aq";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "aq";
  };
})
