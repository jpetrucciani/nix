# [Clef-Flash server](https://github.com/jpetrucciani/clef-flash-server) serves Cloudflare's native decision API on CUDA.
{ callPackage
, uv-nix
, releaseVersion ? "0.1.1"
, releaseHash ? "06f2pkvrgyhhxwhcnlf25zddd80nxbpjk3dnwb95h421zjf884b0"
, serverSource ? uv-nix.fetchGitHubWorkspace {
    owner = "jpetrucciani";
    repo = "clef-flash-server";
    rev = "refs/tags/v${releaseVersion}";
    hash = releaseHash;
  }
, isWSL ? false
, pythonVersion ? "3.13"
}:
let
  releaseUvNix = uv-nix // {
    # Read manifests from the fetched release during read-only evaluation.
    # Apply upstream's fileset filter only to the package's build source.
    mkEnv = args: uv-nix.mkEnv (args // {
      workspaceRoot = serverSource;
      pyprojectOverrides = final: prev:
        let
          overrides = args.pyprojectOverrides final prev;
        in
        overrides // {
          clef-flash-server = overrides.clef-flash-server.overrideAttrs (_: {
            src = args.workspaceRoot;
          });
        };
    });
  };
  callReleasePackage = path: args: callPackage path ({
    callPackage = callReleasePackage;
    uv-nix = releaseUvNix;
  } // args);
in
callReleasePackage (serverSource + "/nix/package.nix") {
  workspaceRoot = serverSource;
  inherit isWSL pythonVersion;
}
