let
  pynixifyOverlay =
    self: super: {
      python39 = super.python39.override { inherit packageOverrides; };
      python310 = super.python310.override { inherit packageOverrides; };
    };

  packageOverrides = self: _: with self; {
    # my packages
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
    types-paramiko = buildPythonPackage rec {
      pname = "types-paramiko";
      version = "2.8.10";

      src = fetchPypi {
        inherit pname version;
        sha256 = "1l3pgb5i7wadihn33q90ykq1ks22c0mk8i7m11x32zhwsv0ybdr5";
      };

      propagatedBuildInputs = [ types-cryptography ];

      meta = with lib; {
        description = "Typing stubs for paramiko";
        homepage = "https://github.com/python/typeshed";
      };
    };
    types-cryptography = buildPythonPackage rec {
      pname = "types-cryptography";
      version = "3.3.13";

      src = fetchPypi {
        inherit pname version;
        sha256 = "0fadhk4hl7wbaqqs1ap5ax0kx2a8f21472y98j965phxmvhn207a";
      };

      propagatedBuildInputs = [ types-enum34 types-ipaddress ];

      meta = with lib; {
        description = "Typing stubs for cryptography";
        homepage = "https://github.com/python/typeshed";
      };
    };
    types-enum34 = buildPythonPackage rec {
      pname = "types-enum34";
      version = "1.1.2";

      src = fetchPypi {
        inherit pname version;
        sha256 = "0akkzwswj6giqhbjkh8lcbyjmqdb81linckhnyr726wsz2n8x812";
      };

      meta = with lib; {
        description = "Typing stubs for enum34";
        homepage = "https://github.com/python/typeshed";
      };
    };
    types-ipaddress = buildPythonPackage rec {
      pname = "types-ipaddress";
      version = "1.0.2";

      src = fetchPypi {
        inherit pname version;
        sha256 = "0k8365554r68f9y0k5bjslqzflbjn19lnrbm1k09xaxb3mg9mwmk";
      };

      meta = with lib; {
        description = "Typing stubs for ipaddress";
        homepage = "https://github.com/python/typeshed";
      };
    };
  };
in
pynixifyOverlay
