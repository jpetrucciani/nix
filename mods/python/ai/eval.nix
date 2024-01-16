final: prev:
let
  inherit (prev) buildPythonPackage fetchPypi;
  inherit (prev.lib) licenses maintainers;
in
{
  langfuse = buildPythonPackage rec {
    pname = "langfuse";
    version = "2.6.0";
    format = "pyproject";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-JCxvtL55OJbaYdqGjT72O3tzRtiSP9ogISp4Zl2hI+k=";
    };

    nativeBuildInputs = with prev; [
      pythonRelaxDepsHook
      poetry-core
    ];

    pythonRelaxDeps = [
      "chevron"
      "wrapt"
    ];

    propagatedBuildInputs = with prev; [
      attrs
      backoff
      chevron
      httpx
      langchain
      monotonic
      pydantic
      python-dateutil
      pytz
      wrapt
    ];

    pythonImportsCheck = [ "langfuse" ];

    meta = {
      description = "A client library for accessing langfuse";
      homepage = "https://pypi.org/project/langfuse/";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };
}
