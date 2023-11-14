final: prev:
let
  inherit (final) pythonAtLeast pythonOlder;
  inherit (final.stdenv) isDarwin;
  inherit (final.pkgs) fetchFromGitHub fetchhg;
  nonCurrentPython = pythonOlder "3.7" || pythonAtLeast "3.13";
  disableCheckPython312 = pkg:
    if (pythonAtLeast "3.12") then
      prev.${pkg}.overridePythonAttrs (_: { doCheck = false; }) else prev.${pkg};
in
rec {
  passlib =
    if isDarwin then
      prev.passlib.overrideAttrs
        (_: {
          disabledTestPaths =
            [
              "passlib/tests/test_context.py"
            ];
        }) else prev.passlib;

  curio =
    if isDarwin then
      prev.curio.overrideAttrs
        (_: {
          doCheck = false;
          doInstallCheck = false;
        }) else prev.curio;

  twisted =
    if isDarwin then
      prev.twisted.overrideAttrs
        (_: {
          doCheck = false;
        }) else prev.twisted;

  cherrypy = prev.cherrypy.overridePythonAttrs (old: {
    disabled = nonCurrentPython;
    doCheck = false;
  });

  watchfiles = prev.watchfiles.overridePythonAttrs (_: {
    doCheck = false;
  });

  slack-bolt = prev.slack-bolt.overridePythonAttrs (old: {
    postPatch = ''
      sed -i '/pytest-runner/d' ./setup.py
    '';
    disabledTests = old.disabledTests ++ [
      "TestAuthorize"
      "TestAsyncAuthorize"
    ];
  });

  aioquic = prev.aioquic.overrideAttrs (_: {
    patches = [ ];
    disabledTestPaths = [ "tests/test_tls.py" "tests/test_asyncio.py" ];
  });

  maxminddb =
    if isDarwin then prev.maxminddb.overrideAttrs (_: { doCheck = false; }) else prev.maxminddb;

  sqlalchemy_1 =
    let
      version = "1.4.48";
    in
    prev.sqlalchemy.overridePythonAttrs (_: {
      inherit version;
      src = prev.fetchPypi {
        inherit version;
        pname = "SQLAlchemy";
        hash = "sha256-tHvChwltmJoIOM6W99jpZpFKJNqHftQadTHUS1XNuN8=";
      };
      passthru.replaceSqlalchemy = old: {
        propagatedBuildInputs = prev.lib.remove prev.sqlalchemy old.propagatedBuildInputs or [ ] ++ [ sqlalchemy_1 ];
      };
      disabledTestPaths = [ ];
      disabledTests = prev.lib.optionals prev.stdenv.isDarwin [
        "MemUsageWBackendTest"
        "MemUsageTest"
      ];
    });

  databases = prev.databases.overridePythonAttrs (old: sqlalchemy_1.replaceSqlalchemy old // {
    meta.broken = false;
  });

  python-multipart = let version = "0.0.6"; in prev.python-multipart.overridePythonAttrs (_: {
    inherit version;
    format = "pyproject";
    src = prev.pkgs.fetchFromGitHub {
      owner = "andrew-d";
      repo = "python-multipart";
      rev = "refs/tags/${version}";
      hash = "sha256-Qadzs6T28xj2L2PsRr4WPfBcBOUa5QTC3i4HyxpOGzU=";
    };
    nativeBuildInputs = with prev; [
      hatch-vcs
      hatchling
    ];
  });

  betterproto = prev.betterproto.overridePythonAttrs (_: {
    src = prev.pkgs.fetchFromGitHub {
      owner = "danielgtaylor";
      repo = "python-betterproto";
      rev = "0adcc9020cf738489e8b21efc653bd883b12d4af";
      hash = "sha256-nQlLFQgwwkCOa3+DliHkWeoxlaS0LN8haXEQ8ARmblY=";
    };
  });
  grpclib = prev.grpclib.overridePythonAttrs (_: { doCheck = false; });

  tensorboard = prev.tensorboard.overridePythonAttrs (_: {
    disabled = false;
  });

  numba = prev.numba.overridePythonAttrs (old: {
    disabled = nonCurrentPython;
  });

  librosa = prev.librosa.overridePythonAttrs (_: {
    disabledTestPaths = [ "tests/test_display.py" ];
  });

  pydevd = prev.pydevd.overridePythonAttrs (_: {
    disabledTestPaths = [
      "tests_python/test_debugger.py"
      "tests_python/test_debugger_json.py"
    ];
  });

  python-binance = prev.python-binance.overridePythonAttrs (old: {
    postPatch = ''
      sed -i -E 's#raise.*#version = "${old.version}"#g' ./setup.py
    '';
    propagatedBuildInputs = old.propagatedBuildInputs ++ [ prev.pycryptodome ];
  });

  emoji_1 = prev.buildPythonPackage rec {
    pname = "emoji";
    version = "1.7.0";
    format = "setuptools";

    disabled = pythonOlder "3.7";

    src = prev.pkgs.fetchFromGitHub {
      owner = "carpedm20";
      repo = pname;
      rev = "refs/tags/v${version}";
      hash = "sha256-vKQ51RP7uy57vP3dOnHZRSp/Wz+YDzeLUR8JnIELE/I=";
    };

    nativeCheckInputs = [
      prev.pytestCheckHook
    ];

    disabledTests = [
      "test_emojize_name_only"
    ];

    pythonImportsCheck = [
      "emoji"
    ];

    meta = with prev.pkgs.lib; {
      description = "Emoji for Python";
      homepage = "https://github.com/carpedm20/emoji/";
      changelog = "https://github.com/carpedm20/emoji/blob/v${version}/CHANGES.md";
      license = licenses.bsd3;
      maintainers = with maintainers; [ joachifm ];
    };
  };

  # wat?
  accelerate = if isDarwin then prev.accelerate.overridePythonAttrs (_: { doCheck = false; }) else prev.accelerate;

  # PYTHON 3.12 FIXES!
  autoflake = disableCheckPython312 "autoflake";
  nose3 = disableCheckPython312 "nose3";
  nosexcover = disableCheckPython312 "nosexcover";
  itsdangerous = disableCheckPython312 "itsdangerous";
  async-generator = disableCheckPython312 "async-generator";
  parameterized = disableCheckPython312 "parameterized";
  pycryptodome = let version = "3.19.0"; in prev.pycryptodome.overridePythonAttrs (_: {
    inherit version;
    src = fetchFromGitHub {
      owner = "Legrandin";
      repo = "pycryptodome";
      rev = "refs/tags/v${version}";
      hash = "sha256-WD+OEjePVtqlmn7h1CIfraLuEQlodkvjmYQ8q7nNoGU=";
    };
  });
  setuptools-rust =
    let
      pname = "setuptools-rust";
      version = "1.7.0";
    in
    if (pythonAtLeast "3.12") then
      prev.setuptools-rust.overridePythonAttrs
        (_: {
          inherit version;
          format = "pyproject";
          src = prev.fetchPypi {
            inherit pname version;
            hash = "sha256-xxAJmZSCNaOK5+VV/hmapmwlPcOEsSX12FRzv4Hq46M=";
          };
        }) else prev.setuptools-rust;
  cffi =
    let
      pname = "cffi";
      version = "1.16.0";
    in
    if (pythonAtLeast "3.12") then
      prev.cffi.overridePythonAttrs
        (_: {
          inherit version;
          src = prev.fetchPypi {
            inherit pname version;
            hash = "sha256-vLPvQ+WGZbvaL7GYaY/K5ndkg+DEpjGqVkeAbCXgLMA=";
          };
          patches = [ ];
        }) else prev.cffi;
  pyflakes =
    let
      pname = "pyflakes";
      version = "3.1.0";
    in
    if (pythonAtLeast "3.12") then
      prev.pyflakes.overridePythonAttrs
        (_: {
          inherit version;
          src = prev.fetchPypi {
            inherit pname version;
            hash = "sha256-oKrgNMRE2wBxqgd5crpHaNQMgw2VOf1Fv0zT+PaZLvw=";
          };
        }) else prev.pyflakes;
  # need to use this commit for python 3.12 to work
  ruamel-yaml-clib =
    if (pythonAtLeast "3.12") then
      prev.ruamel-yaml-clib.overridePythonAttrs
        (_: {
          version = "0.2.8";
          src = fetchhg {
            url = "http://hg.code.sf.net/p/ruamel-yaml-clib/code";
            rev = "5f8ccce2f70b3a5d27c47ce19fe33e5bdd815571";
            sha256 = "sha256-6AizGQLpn887R8D9qbLOc0z514oSArBOkDJ3cabFV2M=";
          };
        }) else prev.ruamel-yaml-clib;

  tokenize-rt = let version = "5.2.0"; in
    if (pythonAtLeast "3.12") then
      prev.tokenize-rt.overridePythonAttrs
        (_: {
          inherit version;
          src = fetchFromGitHub {
            owner = "asottile";
            repo = "tokenize-rt";
            rev = "refs/tags/v${version}";
            hash = "sha256-G4Dn6iZLVOovzfEt9eMzp93mTX+bo0tHI5cCbaJLxBQ=";
          };
        }) else prev.tokenize-rt;

  typeguard = prev.buildPythonPackage rec {
    pname = "typeguard";
    version = "4.1.5";
    pyproject = true;

    src = prev.fetchPypi {
      inherit pname version;
      hash = "sha256-6goRO7wRG8/8kHieuyFWJcljQR9wlqfpBi1ORjDBVf0=";
    };

    nativeBuildInputs = with prev; [
      setuptools
      setuptools-scm
      wheel
    ];

    propagatedBuildInputs = with prev;[
      importlib-metadata
      typing-extensions
    ];

    passthru.optional-dependencies = with prev; {
      doc = [
        packaging
        sphinx
        sphinx-autodoc-typehints
      ];
      test = [
        coverage
        pytest
      ];
    };

    pythonImportsCheck = [ "typeguard" ];

    meta = with prev.pkgs.lib; {
      description = "Run-time type checker for Python";
      homepage = "https://pypi.org/project/typeguard";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  stack-data = prev.buildPythonPackage
    rec {
      pname = "stack-data";
      version = "0.6.3";
      pyproject = true;

      src = prev.fetchPypi {
        pname = "stack_data";
        inherit version;
        hash = "sha256-g2p3jeT+xNzR3Nie2Kv/iiIfWDCEYuHEqio88wFI8Lk=";
      };

      nativeBuildInputs = with prev; [
        setuptools
        setuptools-scm
        wheel
      ];

      propagatedBuildInputs = with prev; [
        asttokens
        executing
        pure-eval
      ];

      passthru.optional-dependencies = with prev; {
        tests = [
          cython
          littleutils
          pygments
          pytest
          typeguard
        ];
      };

      pythonImportsCheck = [ "stack_data" ];

      meta = with prev.pkgs.lib; {
        description = "Extract data from python stack frames and tracebacks for informative displays";
        homepage = "https://pypi.org/project/stack-data/";
        license = licenses.mit;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };

  tenacity = prev.tenacity.overridePythonAttrs (_: {
    disabledTests = [ "test_retry_type_annotations" ];
  });
}
