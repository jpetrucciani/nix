{ lib
, buildNpmPackage
, fetchurl
, refresh_e2b_cli
}:
let
  lockHash = "sha256-vFi6exIhVgqbNwyNngAdhzEPdGtbUNMHSK2aUdlnfAg=";
  lockUrl = "https://static.g7c.us/lock/npm/e2b-cli/${version}.lock";
  packageLock = fetchurl {
    url = lockUrl;
    hash = lockHash;
  };
  version = "2.17.1";
in
buildNpmPackage (finalAttrs: {
  pname = "e2b-cli";
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@e2b/cli/-/cli-${finalAttrs.version}.tgz";
    hash = "sha512-urMsBCJVcDFkDgxWkNuE0r9wFWXge3bSoeOJO+8IX+OYP6sZzXuOaxqBUDh+T/P/hTFOFeK09LkQyQhl5vligA==";
  };

  postPatch = ''
    cp ${packageLock} package-lock.json
  '';

  dontNpmBuild = true;
  npmDepsHash = "sha256-msk3k/bx2YNoBcA6FJi7/U/yKIBfNNjZQnAZso/Qi7U=";

  passthru = {
    inherit lockHash lockUrl;
    updateScript = refresh_e2b_cli;
  };

  meta = {
    description = "Command-line interface for E2B sandboxes";
    homepage = "https://github.com/e2b-dev/e2b";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jpetrucciani ];
    mainProgram = "e2b";
    skipBuild = true;
  };
})
