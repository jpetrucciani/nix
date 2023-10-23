final: prev:
let
  inherit (prev) buildPythonPackage fetchPypi;
  inherit (prev.lib) licenses maintainers;
in
{
  langfuse = buildPythonPackage rec {
    pname = "langfuse";
    version = "1.0.41";
    format = "pyproject";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-OM7wmLo9dcrh2SEjPDtOQclfJwPc9q1LIax/4qYujPo=";
    };

    nativeBuildInputs = with prev; [
      poetry-core
    ];

    propagatedBuildInputs = with prev; [
      attrs
      backoff
      httpx
      langchain
      pydantic
      python-dateutil
      pytz
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
