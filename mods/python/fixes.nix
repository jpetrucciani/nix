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

    certbot = super.certbot.overridePythonAttrs (_: {
      src = super.pkgs.fetchFromGitHub {
        owner = "certbot";
        repo = "certbot";
        rev = "refs/tags/v2.4.0";
        hash = "sha256-BQsdhlYABZtz5+SORiCVnWMZdMmiWGM9W1YLqObyFo8=";
      };
    });

    # databases = super.databases.overridePythonAttrs (_: {
    #   version = "0.7.1";
    #   src = super.pkgs.fetchFromGitHub {
    #     owner = "encode";
    #     repo = "databases";
    #     rev = "deedd134a9fce3c45ce7e79ebc3d420a034020bd";
    #     hash = "sha256-WlJbl3r16WwVi/McuisU1tu9/CZZ8oL+K0dQY6lYQ+Y=";
    #   };
    #   meta.broken = false;
    # });

  })
  [ "python310" "python311" ]
  final
  prev
