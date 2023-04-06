final: prev:
let
  inherit (prev.stdenv) isDarwin;
in
{
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

  slack-sdk =
    if isDarwin then
      prev.slack-sdk.overridePythonAttrs
        (_: {
          doCheck = false;
        }) else prev.slack-sdk;

  certbot = prev.certbot.overridePythonAttrs (_: {
    src = prev.pkgs.fetchFromGitHub {
      owner = "certbot";
      repo = "certbot";
      rev = "refs/tags/v2.4.0";
      hash = "sha256-BQsdhlYABZtz5+SORiCVnWMZdMmiWGM9W1YLqObyFo8=";
    };
  });

  # databases = prev.databases.overridePythonAttrs (_: {
  #   version = "0.7.1";
  #   src = prev.pkgs.fetchFromGitHub {
  #     owner = "encode";
  #     repo = "databases";
  #     rev = "deedd134a9fce3c45ce7e79ebc3d420a034020bd";
  #     hash = "sha256-WlJbl3r16WwVi/McuisU1tu9/CZZ8oL+K0dQY6lYQ+Y=";
  #   };
  #   meta.broken = false;
  # });

}
