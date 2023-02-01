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

    inflect = super.inflect.overridePythonAttrs (old: rec {
      version = "5.6.2";
      src = super.fetchPypi {
        inherit version;
        pname = "inflect";
        sha256 = "sha256-qtx+1zko9eAUEpeUu6wDBYzKNdCpc6X8TrRcf6JgBfk=";
      };
    });
    pyramid = super.pyramid.overrideAttrs (_: {
      doInstallCheck = false;
    });
  })
  [ "python310" "python311" ]
  final
  prev
