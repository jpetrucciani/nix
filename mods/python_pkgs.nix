let
  pynixifyOverlay =
    self: super: {
      python39 = super.python39.override { inherit packageOverrides; };
      python310 = super.python310.override { inherit packageOverrides; };
    };

  packageOverrides = self: super: with self; {
    # fixes for mac
    dnspython =
      if super.stdenv.isDarwin then
        super.dnspython.overrideAttrs
          (_: {
            disabledTestPaths =
              [
                "tests/test_async.py"
                "tests/test_query.py"
                "tests/test_resolver.py"
                "tests/test_resolver_override.py"
              ];
          }) else super.dnspython;
    httplib2 =
      if super.stdenv.isDarwin then
        super.httplib2.overrideAttrs
          (_: {
            disabledTests =
              [
                "test_connection_close"
                "test_timeout_subsequent"
                "test_client_cert_password_verified"
              ];
          }) else super.httplib2;
    passlib =
      if super.stdenv.isDarwin then
        super.passlib.overrideAttrs
          (_: {
            disabledTests =
              [
                "test_dummy_verify"
              ];
          }) else super.passlib;

    # my packages
    archives = buildPythonPackage rec {
      pname = "archives";
      version = "0.12";

      src = fetchPypi {
        inherit pname version;
        sha256 = "10frsfmbd8cc8dv3dayfd68msk8ah0kvlr2yyx5y7l1vrmcsgxy8";
      };

      propagatedBuildInputs = [ click typed-ast radon ];

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
      version = "2.8.13";

      src = fetchPypi {
        inherit pname version;
        sha256 = "0xk5xqhfl3xmzrnzb17c5hj5zbh7fpyfyj35zjma32iivfkqd8lp";
      };

      pythonImportsCheck = [
        "paramiko-stubs"
      ];

      propagatedBuildInputs = [ types-cryptography ];

      meta = with lib; {
        description = "Typing stubs for paramiko";
        homepage = "https://github.com/python/typeshed";
      };
    };

    types-cryptography = buildPythonPackage rec {
      pname = "types-cryptography";
      version = "3.3.15";

      src = fetchPypi {
        inherit pname version;
        sha256 = "0fr70phvg3zc4h41mv48g04x3f20y478y01ji3w1i2mqlxskm657";
      };

      pythonImportsCheck = [
        "cryptography-stubs"
      ];

      propagatedBuildInputs = [ types-enum34 types-ipaddress ];

      meta = with lib; {
        description = "Typing stubs for cryptography";
        homepage = "https://github.com/python/typeshed";
      };
    };

    types-enum34 = buildPythonPackage rec {
      pname = "types-enum34";
      version = "1.1.8";

      src = fetchPypi {
        inherit pname version;
        sha256 = "0421lr89vv3fpg77kkj5nmzd7z3nmhw4vh8ibsjp6vfh86b7d73g";
      };

      pythonImportsCheck = [
        "enum-python2-stubs"
      ];

      meta = with lib; {
        description = "Typing stubs for enum34";
        homepage = "https://github.com/python/typeshed";
      };
    };

    types-ipaddress = buildPythonPackage rec {
      pname = "types-ipaddress";
      version = "1.0.8";

      src = fetchPypi {
        inherit pname version;
        sha256 = "0h9q9pjvw1ap5k70ygp750d096jkzymxlhx87yh0pr9mb6zg6gd0";
      };

      pythonImportsCheck = [
        "ipaddress-python2-stubs"
      ];

      meta = with lib; {
        description = "Typing stubs for ipaddress";
        homepage = "https://github.com/python/typeshed";
      };
    };

    boto3-stubs = buildPythonPackage rec {
      pname = "boto3-stubs";
      version = "1.20.35";

      src = fetchPypi {
        inherit pname version;
        sha256 = "1nnd8jjakbcfjsfwn0w7i8mkqj7zji7x2vzmgklbrh3hw10ig95p";
      };

      propagatedBuildInputs = [ botocore-stubs ];
      checkInputs = [
        boto3
      ];
      pythonImportsCheck = [
        "boto3-stubs"
      ];

      meta = with lib; {
        description =
          "Type annotations for boto3 1.20.35, generated by mypy-boto3-builder 6.3.1";
        homepage = "https://github.com/vemel/mypy_boto3_builder";
      };
    };

    botocore-stubs = buildPythonPackage rec {
      pname = "botocore-stubs";
      version = "1.24.6";

      src = fetchPypi {
        inherit pname version;
        sha256 = "093zsj2wk7xw89yvs7w88z9w3811vkpgfv4q3wk9j6gd6n3hr1pw";
      };

      pythonImportsCheck = [
        "botocore-stubs"
      ];

      meta = with lib; {
        description =
          "Type annotations for botocore 1.24.6 generated with mypy-boto3-builder 7.1.2";
        homepage = "https://github.com/vemel/mypy_boto3_builder";
      };
    };

  };
in
pynixifyOverlay
