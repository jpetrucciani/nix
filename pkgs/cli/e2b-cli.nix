{ lib
, buildNpmPackage
, fetchurl
}:
let
  pname = "e2b-cli";
  version = "2.3.0";
  lockfile = fetchurl { url = "https://static.g7c.us/lock/npm/${pname}/${version}.lock"; hash = "sha256-rJxv1yg9ppOJ+7lQmPsS4xZfhMtNiEFX1Nzv1dy5GAg="; };
in
buildNpmPackage {
  inherit pname version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@e2b/cli/-/cli-${version}.tgz";
    hash = "sha256-+HV2PACG2fBIV+00inwvl0fKkygAvl38pray7EGLiIg=";
  };

  postPatch = ''
    cp ${lockfile} package-lock.json
  '';

  dontNpmBuild = true;
  npmDepsHash = "sha256-ViSARJBSfFkOA/nwmqJm2uFxUvMXVX30Ta/nAgiGavY=";
  meta = with lib; {
    description = "e2b";
    homepage = "https://github.com/e2b-dev/e2b";
    license = licenses.asl20;
  };
}
