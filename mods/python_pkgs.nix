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

    archives = buildPythonPackage rec {
      pname = "archives";
      version = "0.12";

      src = fetchPypi {
        inherit pname version;
        sha256 = "10frsfmbd8cc8dv3dayfd68msk8ah0kvlr2yyx5y7l1vrmcsgxy8";
      };

      propagatedBuildInputs = [ click typed-ast radon ];

      # doCheck = false;

      meta = with lib; {
        description = "a new way to do python code documentation";
        homepage = "https://github.com/jpetrucciani/archives.git";
      };
    };

    # requirements for other packages
    radon = buildPythonPackage rec {
      pname = "radon";
      version = "5.1.0";

      src = fetchPypi {
        inherit pname version;
        sha256 = "1vmf56zsf3paa1jadjcjghiv2kxwiismyayq42ggnqpqwm98f7fb";
      };

      propagatedBuildInputs = [ mando colorama future ];

      doCheck = false;

      meta = with lib; {
        description = "Code Metrics in Python";
        homepage = "https://radon.readthedocs.org/";
      };
    };

    mando = buildPythonPackage rec {
      pname = "mando";
      version = "0.6.4";

      src = fetchPypi {
        inherit pname version;
        sha256 = "0q6rl085q1hw1wic52pqfndr0x3nirbxnhqj9akdm5zhq2fv3zkr";
      };

      propagatedBuildInputs = [ six ];

      doCheck = false;

      meta = with lib; {
        description = "Create Python CLI apps with little to no effort at all!";
        homepage = "https://mando.readthedocs.org/";
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
