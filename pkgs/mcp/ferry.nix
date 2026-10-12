# [`ferry`](https://github.com/jpetrucciani/ferry) is a stdio/sse/streamable http transport to ferry your mcp access across the network/proxies
{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "ferry";
  version = "0.0.2";

  src = fetchFromGitHub {
    owner = "jpetrucciani";
    repo = "ferry";
    tag = "v${finalAttrs.version}";
    hash = "sha256-1YpuMJNVF4/zxgupZnN/kVchjBv0lGzsB1NgYyJvJ7U=";
  };

  cargoHash = "sha256-SkkYGa7d+EvyjpN/9YkYK+MFshPwdXPjdZFhs/cRl20=";

  meta = {
    description = "a stdio/sse/streamable http transport to ferry your mcp access across the network/proxies";
    homepage = "https://github.com/jpetrucciani/ferry";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "ferry";
  };
})
