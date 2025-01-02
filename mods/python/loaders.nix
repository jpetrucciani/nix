final: prev:
let
  inherit (final) buildPythonPackage;
  inherit (final.lib) licenses maintainers;
  inherit (final.pkgs) fetchFromGitHub;
in
{
  selectolax = buildPythonPackage rec {
    pname = "selectolax";
    version = "0.3.21";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "rushter";
      repo = "selectolax";
      rev = "v${version}";
      hash = "sha256-Ab09I0CUq/FB4Rtl+ccgr9ap7vCAeujdSNTmCVjEOjs=";
      fetchSubmodules = true;
    };

    nativeBuildInputs = with final; [
      cython
      setuptools
      wheel
    ];

    pythonImportsCheck = [ "selectolax" ];

    meta = {
      description = "Python binding to Modest and Lexbor engines (fast HTML5 parser with CSS selectors";
      homepage = "https://github.com/rushter/selectolax";
      changelog = "https://github.com/rushter/selectolax/blob/${src.rev}/CHANGES.rst";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };
}
