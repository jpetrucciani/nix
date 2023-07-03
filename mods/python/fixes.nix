final: prev:
let
  inherit (prev) fetchPypi;
  inherit (prev.pkgs) fetchFromGitHub;
  inherit (prev.stdenv) isDarwin;
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

  aioquic = prev.aioquic.overrideAttrs (_: {
    patches = [ ];
    disabledTestPaths = [ "tests/test_tls.py" ];
  });

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
    });

  databases = prev.databases.overridePythonAttrs (old: sqlalchemy_1.replaceSqlalchemy old // {
    meta.broken = false;
  });

  python-multipart = let version = "0.0.6"; in prev.python-multipart.overridePythonAttrs (_: {
    inherit version;
    format = "pyproject";
    src = fetchFromGitHub {
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
    src = fetchFromGitHub {
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

  llvmlite =
    let
      inherit (prev) pythonOlder;
      inherit (prev.pkgs) llvm_14;
      pname = "llvmlite";
      version = "0.40.0";
    in
    (prev.llvmlite.override { llvm = llvm_14; }).overridePythonAttrs (old: {
      inherit version;
      format = "setuptools";
      disabled = pythonOlder "3.8";
      propagatedBuildInputs = [ ];
      env.LLVMLITE_CXX_STATIC_LINK = 0;
      postPatch = ''
        substituteInPlace llvmlite/tests/test_binding.py --replace "test_linux" "nope"
      '';
      checkPhase = ''
        runHook preCheck
        ${old.checkPhase}
        runHook postCheck
      '';
      src = prev.fetchPypi {
        inherit pname version;
        hash = "sha256-yRC4+/1nuOnQsQ68ASsjzWfL7O8blvANOR3dKY1xZxw=";
      };
    });
  numba =
    let
      inherit (prev) lib pythonOlder pythonAtLeast fetchPypi;
      pname = "numba";
      version = "0.57.0";
      pop = l: (lib.lists.remove (builtins.head l) l);
    in
    prev.numba.overridePythonAttrs (old: {
      inherit version;
      disabled = pythonOlder "3.7" || pythonAtLeast "3.12";
      src = fetchPypi {
        inherit pname version;
        hash = "sha256-KvbYEGelvcE5YMbSUZ26u/TV1ZfPddZAxa6u/UjGQgo=";
      };
      postPatch = "";
      patches = pop (pop old.patches);
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

  cattrs =
    let
      pname = "cattrs";
      version = "23.1.2";
    in
    prev.cattrs.overridePythonAttrs (old: {
      inherit version;
      src = fetchFromGitHub {
        owner = "python-attrs";
        repo = pname;
        rev = "v${version}";
        hash = "sha256-YO4Clbo5fmXbysxwwM2qCHJwO5KwDC05VctRVFruJcw=";
      };
      disabledTestPaths = old.disabledTestPaths ++ [ "tests/test_typeddicts.py" ];
      nativeCheckInputs = old.nativeCheckInputs ++ (with prev; [ cbor2 typing-extensions ]);
    });

  attrs =
    let
      pname = "attrs";
      version = "23.1.0";
    in
    prev.attrs.overridePythonAttrs (_: {
      inherit version;
      src = fetchPypi {
        inherit pname version;
        hash = "sha256-YnmDbVgVE6JvG/I1+azTM7yRFWg/FPfo+uRsmPxQ4BU=";
      };
      postPatch = ''
        sed -i -E '/tool.hatch.metadata.hooks.fancy-pypi-readme.fragments/,/^\"\"\"/d' ./pyproject.toml
        sed -i -E '/tool.hatch.metadata.hooks.fancy-pypi-readme/,/^content-type/d' ./pyproject.toml
        sed -i -E '/tool.hatch.version/,/^raw-options/d' ./pyproject.toml
        sed -i -E 's/(name = \"attrs\")/\1\nversion = \"${version}\"/g' ./pyproject.toml
        sed -i -E '/dynamic = \[/d' ./pyproject.toml
      '';
      nativeBuildInputs = [
        # prev.hatch-fancy-pypi-readme
        # prev.hatch-vcs
        prev.hatchling
      ];
    });
}
