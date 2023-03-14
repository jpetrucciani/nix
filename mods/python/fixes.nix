final: prev: prev.hax.pythonPackageOverlay
  (self: super:
  let
    inherit (super.stdenv) isDarwin;
  in
  {
    passlib =
      if isDarwin then
        super.passlib.overrideAttrs
          (_: {
            disabledTestPaths =
              [
                "passlib/tests/test_context.py"
              ];
          }) else super.passlib;

    curio =
      if isDarwin then
        super.curio.overrideAttrs
          (_: {
            doCheck = false;
            doInstallCheck = false;
          }) else super.curio;

    aioquic = super.aioquic.overrideAttrs (_: {
      patches = [ ];
      disabledTestPaths = [ "tests/test_tls.py" ];
    });

    slack-sdk =
      if isDarwin then
        super.slack-sdk.overridePythonAttrs
          (_: {
            doCheck = false;
          }) else super.slack-sdk;

  })
  [ "python310" "python311" ]
  final
  prev
