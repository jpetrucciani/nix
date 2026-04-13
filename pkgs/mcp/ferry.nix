# [`ferry`](https://github.com/jpetrucciani/ferry) is a stdio/sse/streamable http transport to ferry your mcp access across the network/proxies
{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "ferry";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "jpetrucciani";
    repo = "ferry";
    tag = "v${finalAttrs.version}";
    hash = "sha256-SuuXTdbgBCZ+Wvyu+EzGdA+nOKZBis/Jf1+hm/JhfjM=";
  };

  cargoHash = "sha256-Hj7z0MFDhEFzA4aEOOTi41VYsUcRNvae69mYwXgIgKs=";

  meta = {
    description = "a stdio/sse/streamable http transport to ferry your mcp access across the network/proxies";
    homepage = "https://github.com/jpetrucciani/ferry";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "ferry";
  };
})
