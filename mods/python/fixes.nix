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

    mocket = super.mocket.overridePythonAttrs (old: {
      pytestFlagsArray = old.pytestFlagsArray ++ [
        "--ignore=tests/main/test_http_aiohttp.py"
        "--ignore=tests/tests38/test_http_aiohttp.py"
      ];
    });

    geoip2 = super.geoip2.overridePythonAttrs (old: {
      disabledTestPaths = [
        "tests/webservice_test.py"
      ];
    });
  })
  [ "python310" "python311" ]
  final
  prev
