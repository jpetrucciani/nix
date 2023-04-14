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
      version = "1.4.47";
    in
    prev.sqlalchemy.overridePythonAttrs (_: {
      inherit version;
      src = prev.fetchPypi {
        inherit version;
        pname = "SQLAlchemy";
        hash = "sha256-lfwC9/wfMZmqpHqKdXQ3E0z2GOnZlMhO/9U/Uww4WG8=";
      };
      passthru.replaceSqlalchemy = old: {
        propagatedBuildInputs = prev.lib.remove prev.sqlalchemy old.propagatedBuildInputs or [ ] ++ [ sqlalchemy_1 ];
      };
    });

  slack-sdk =
    let
      version = "3.21.1";
    in
    prev.slack-sdk.overridePythonAttrs (old: sqlalchemy_1.replaceSqlalchemy old // {
      inherit version;
      src = prev.fetchPypi {
        inherit version;
        pname = "slack_sdk";
        hash = "sha256-RR8jlPbTaW0IybKQhEMyqrbo45RzMn/D99GXlMfrRB0=";
      };
      doCheck = false;
    });

  databases = prev.databases.overridePythonAttrs (old: sqlalchemy_1.replaceSqlalchemy old // {
    meta.broken = false;
  });

}
