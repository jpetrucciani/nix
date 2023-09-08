final: prev:
let
  inherit (prev) buildPythonPackage fetchPypi;
  inherit (prev.lib) licenses maintainers;
in
{
  langfuse = buildPythonPackage rec {
    pname = "langfuse";
    version = "1.0.17";
    format = "pyproject";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-wt2rmnXkgX5t03S0gJLc0xflTZoLrTsJK9fb/kUrRqs=";
    };

    nativeBuildInputs = with prev; [
      poetry-core
    ];

    propagatedBuildInputs = with prev; [
      attrs
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
      maintainers = with maintainers; [ ];
    };
  };
}
