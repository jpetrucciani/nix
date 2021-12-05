let
  pynixifyOverlay =
    self: super: {
      python39 = super.python39.override { inherit packageOverrides; };
      python310 = super.python310.override { inherit packageOverrides; };
    };

  packageOverrides = self: super: with self; {
    # my packages
    gamble = buildPythonPackage rec {
      pname = "gamble";
      version = "0.10";

      src = fetchPypi {
        inherit pname version;
        sha256 = "1lb5x076blnnz2hj7k92pyq0drbjwsls6pmnabpvyvs4ddhz5w9w";
      };

      checkInputs = [
        pytestCheckHook
      ];

      meta = with lib; {
        description = "a collection of gambling classes/tools";
        homepage = "https://github.com/jpetrucciani/gamble.git";
      };
    };

    # type annotations
    types-tabulate = buildPythonPackage rec {
      pname = "types-tabulate";
      version = "0.8.3";

      src = fetchPypi {
        inherit pname version;
        sha256 = "118x3n6maz38l2a94k8pafrnfgjb7svw1p9cvkpysgpi6lxwla3w";
      };

      meta = with lib; {
        description = "Typing stubs for tabulate";
        homepage = "https://github.com/python/typeshed";
      };
    };
  };
in
pynixifyOverlay
