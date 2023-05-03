final: prev:
let
  inherit (prev.stdenv) isDarwin;
in
rec {
  passlib =
    if isDarwin then
      prev.passlib.overrideAttrs
        (_: {
          disabledTestPaths =
            [
              "passlib/tests/test_context.py"
            ];
        }) else prev.passlib;

  curio =
    if isDarwin then
      prev.curio.overrideAttrs
        (_: {
          doCheck = false;
          doInstallCheck = false;
        }) else prev.curio;

  aioquic = prev.aioquic.overrideAttrs (_: {
    patches = [ ];
    disabledTestPaths = [ "tests/test_tls.py" ];
  });

  sqlalchemy_1 =
    let
      version = "1.4.48";
    in
    prev.sqlalchemy.overridePythonAttrs (_: {
      inherit version;
      src = prev.fetchPypi {
        inherit version;
        pname = "SQLAlchemy";
        hash = "sha256-tHvChwltmJoIOM6W99jpZpFKJNqHftQadTHUS1XNuN8=";
      };
      passthru.replaceSqlalchemy = old: {
        propagatedBuildInputs = prev.lib.remove prev.sqlalchemy old.propagatedBuildInputs or [ ] ++ [ sqlalchemy_1 ];
      };
    });

  databases = prev.databases.overridePythonAttrs (old: sqlalchemy_1.replaceSqlalchemy old // {
    meta.broken = false;
  });

  nbdime = let version = "3.2.1"; in prev.nbdime.overridePythonAttrs (_: {
    inherit version;
    src = prev.fetchPypi {
      inherit version;
      pname = "nbdime";
      hash = "sha256-MUCaMPhI/8azJUBpfoLVoKG4TcwycWynTni8xLRXxFM=";
    };
    meta.broken = false;
  });

  python-multipart = let version = "0.0.6"; in prev.python-multipart.overridePythonAttrs (_: {
    inherit version;
    format = "pyproject";
    src = prev.pkgs.fetchFromGitHub {
      owner = "andrew-d";
      repo = "python-multipart";
      rev = "refs/tags/${version}";
      hash = "sha256-Qadzs6T28xj2L2PsRr4WPfBcBOUa5QTC3i4HyxpOGzU=";
    };
    nativeBuildInputs = with prev; [
      hatch-vcs
      hatchling
    ];
  });
}
