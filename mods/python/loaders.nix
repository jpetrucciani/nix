final: prev:
let
  inherit (final) buildPythonPackage fetchPypi;
  inherit (final.lib) licenses maintainers;
  inherit (final.pkgs) fetchFromGitHub;
in
{
  docx2txt = buildPythonPackage
    rec {
      pname = "docx2txt";
      version = "0.8";
      format = "setuptools";

      src = fetchPypi {
        inherit pname version;
        hash = "sha256-LAbZjXz+LTlH5XYKV9kk4/8HdFs3nIc3cjki5wCSNuU=";
      };

      pythonImportsCheck = [ "docx2txt" ];

      meta = {
        description = "A pure python-based utility to extract text and images from docx files";
        homepage = "https://github.com/ankushshah89/python-docx2txt";
        license = licenses.mit;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };

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
