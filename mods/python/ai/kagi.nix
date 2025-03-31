final: prev:
let
  inherit (final) buildPythonPackage fetchPypi;
  inherit (final.lib) licenses maintainers;
in
{
  vectordb = buildPythonPackage rec {
    pname = "vectordb";
    version = "0.1.3";
    pyproject = true;

    src = fetchPypi {
      inherit version;
      pname = "${pname}2";
      hash = "sha256-ldrYV3SJ8tIE10FeIkCZHCzHwSBbeRnPhCqRRk+dZ+0=";
    };

    nativeBuildInputs = with final; [
      setuptools
      wheel
    ];

    propagatedBuildInputs = with final; [
      faiss
      numpy
      scikit-learn
      scipy
      sentence-transformers
      spacy
      # tensorflow-text
      torch
      transformers
    ];

    # tests try to load models
    doCheck = false;

    # import check also attempts to load models
    # pythonImportsCheck = [ "vectordb" ];

    meta = {
      description = "A lightweight Python package for storing and retrieving text using chunking, embedding, and vector search";
      homepage = "https://github.com/kagisearch/vectordb";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };
}
