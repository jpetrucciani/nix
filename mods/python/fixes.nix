final: prev:
let
  inherit (final) pythonAtLeast pythonOlder;
  inherit (final.stdenv) isDarwin;
  inherit (final.pkgs) fetchFromGitHub;
  nonCurrentPython = pythonOlder "3.8" || pythonAtLeast "3.13";
  # disableCheckPython312 = pkg:
  #   if (pythonAtLeast "3.12") then
  #     prev.${pkg}.overridePythonAttrs (_: { doCheck = false; }) else prev.${pkg};
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

  # from https://github.com/NixOS/nixpkgs/pull/326321
  python-ldap =
    if (pythonAtLeast "3.12") then
      prev.python-ldap.overridePythonAttrs
        (_: {
          disabled = false;
          build-system = [
            (final.setuptools.overrideAttrs {
              postPatch = ''
                substituteInPlace setuptools/_distutils/util.py \
                  --replace-fail \
                    "from distutils.util import byte_compile" \
                    "from setuptools._distutils.util import byte_compile"
              '';
            })
          ];
        }) else prev.python-ldap;

  # maxminddb =
  #   if isDarwin then prev.maxminddb.overrideAttrs (_: { doCheck = false; }) else prev.maxminddb;

  # black =
  #   if isDarwin then prev.black.overrideAttrs (_: { doCheck = false; }) else prev.black;

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

  betterproto = prev.betterproto.overridePythonAttrs (_: {
    src = prev.pkgs.fetchFromGitHub {
      owner = "danielgtaylor";
      repo = "python-betterproto";
      rev = "0adcc9020cf738489e8b21efc653bd883b12d4af";
      hash = "sha256-nQlLFQgwwkCOa3+DliHkWeoxlaS0LN8haXEQ8ARmblY=";
    };
  });
  # grpclib = prev.grpclib.overridePythonAttrs (_: { doCheck = false; });

  numba = prev.numba.overridePythonAttrs (old: {
    disabled = nonCurrentPython;
  });

  librosa = prev.librosa.overridePythonAttrs (_: {
    doCheck = false;
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

  fastcore = prev.fastcore.overridePythonAttrs (_:
    let version = "1.6.1"; in {
      inherit version;
      src = prev.pkgs.fetchFromGitHub {
        owner = "fastai";
        repo = "fastcore";
        rev = "refs/tags/${version}";
        hash = "sha256-dVzJtYnsezk7Pb5Y59BUY8TQ/3Z5JLntqjld2zJk6pA=";
      };
    });
}
