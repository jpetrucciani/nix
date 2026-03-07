{ lib
, rustPlatform
, fetchFromGitHub
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "carat";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "gemologic";
    repo = "carat";
    tag = "v${finalAttrs.version}";
    hash = "sha256-4LfShXE1wkMDDxzYQtNHwWJRn5rHJjnkclphHm8GZeU=";
  };

  cargoHash = "sha256-wUZPVo5KA7PTtNNj/fCX8nliF3MmHERfDUdalK6oSHE=";

  meta = {
    description = "a quick cli tool to estimate token count";
    homepage = "https://github.com/gemologic/carat";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "carat";
  };
})
