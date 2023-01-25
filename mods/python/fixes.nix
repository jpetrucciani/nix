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

    anybadge = super.anybadge.overridePythonAttrs (old: {
      nativeCheckInputs = old.nativeCheckInputs ++ [ super.requests ];
      propagatedBuildInputs = [ super.packaging ];
      disabledTests = [
        "test_module_same_output_as_main_cli"
        "test_server_badge_request"
        "test_server_is_running"
        "test_server_module_same_output_as_server_cli"
        "test_server_root_request"
      ];
    });
  })
  [ "python310" "python311" ]
  final
  prev
