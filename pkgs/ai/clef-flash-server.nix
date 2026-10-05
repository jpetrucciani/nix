# [Clef-Flash server](https://github.com/jpetrucciani/clef-flash-server) serves Cloudflare's native decision API on CUDA.
{ callPackage
, uv-nix
, releaseVersion ? "0.1.0"
, releaseHash ? "0fpphcvdj2zyvjawxm9qpcabndzdybrppn43x3m0q65a98h150f3"
, serverSource ? uv-nix.fetchGitHubWorkspace {
    owner = "jpetrucciani";
    repo = "clef-flash-server";
    rev = "refs/tags/v${releaseVersion}";
    hash = releaseHash;
  }
, isWSL ? false
, pythonVersion ? "3.13"
}:
callPackage (serverSource + "/nix/package.nix") {
  workspaceRoot = serverSource;
  inherit isWSL pythonVersion;
}
