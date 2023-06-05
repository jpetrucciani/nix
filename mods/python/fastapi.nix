final: prev: with prev; rec {

  asgi-lifespan = buildPythonPackage rec {
    pname = "asgi-lifespan";
    version = "2.0.0";

    format = "setuptools";
    src = pkgs.fetchFromGitHub {
      owner = "florimondmanca";
      repo = pname;
      rev = version;
      hash = "sha256-wKwvCuHupAxIGxW53vUpIxcA1yx4kpWDX/coiNk+3MI=";
    };


    pythonImportsCheck = [
      "asgi_lifespan"
    ];

    preCheck = ''
      cp ./setup.cfg ./setup.cfg.bak
      sed '/addopts =/Q' ./setup.cfg.bak >./setup.cfg
    '';

    nativeCheckInputs = [
      pytestCheckHook
      pytest-asyncio
      starlette
      trio
    ];

    propagatedBuildInputs = [
      sniffio
    ];

    meta = with lib; {
      description = "Programmatic startup/shutdown of ASGI apps";
      homepage = "https://github.com/florimondmanca/asgi-lifespan-db";
      license = licenses.mit;
    };
  };

  httpx-oauth = buildPythonPackage rec {
    pname = "httpx-oauth";
    version = "0.11.0";

    format = "pyproject";
    src = pkgs.fetchFromGitHub {
      owner = "frankie567";
      repo = pname;
      rev = "v${version}";
      hash = "sha256-zmoGr60hEudra3Bgt2sd+aovpvXmvfNL/LAcgkDI678=";
    };

    preBuild =
      let
        sed = "sed -i -E";
      in
      ''
        ${sed} '/dynamic =/d' ./pyproject.toml
        ${sed} '/addopts =/d' ./pyproject.toml
        ${sed} 's#(\[project\])#\1\nversion = "${version}"#g' ./pyproject.toml
      '';

    pythonImportsCheck = [
      "httpx_oauth"
    ];

    nativeBuildInputs = [
      hatch-vcs
      hatchling
    ];

    nativeCheckInputs = [
      pytestCheckHook
      pytest-asyncio
      pytest-mock
      fastapi
      respx
    ];

    propagatedBuildInputs = [
      httpx
    ];

    meta = with lib; {
      description = "";
      homepage = "https://github.com/frankie567/httpx-oauth";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };


  prometheus-fastapi-instrumentator = buildPythonPackage rec {
    pname = "prometheus-fastapi-instrumentator";
    version = "6.0.0";

    format = "pyproject";
    src = pkgs.fetchFromGitHub {
      owner = "trallnag";
      repo = pname;
      rev = "v${version}";
      hash = "sha256-VVDsMwd/d2hnhM9ZHCkWUVkaGrw1wgLzFDF2mK24r0o=";
    };

    preBuild =
      let
        sed = "sed -i -E";
      in
      ''
        ${sed} '/asyncio_mode =/d' ./pyproject.toml
      '';

    pythonImportsCheck = [
      "prometheus_fastapi_instrumentator"
    ];

    nativeBuildInputs = [
      poetry-core
    ];

    nativeCheckInputs = [
      pytestCheckHook
      requests
    ];

    disabledTestPaths = [
      "tests/test_instrumentator_multiple_apps.py"
    ] ++ (if prev.stdenv.isDarwin then [ "tests/test_instrumentation.py" ] else [ ]);

    propagatedBuildInputs = [
      fastapi
      prometheus-client
    ];

    meta = with lib; {
      description = "Instrument your FastAPI app";
      homepage = "https://github.com/trallnag/prometheus-fastapi-instrumentator";
      license = licenses.isc;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  fastapi-users = buildPythonPackage rec {
    pname = "fastapi-users";
    version = "10.4.0";

    format = "pyproject";
    src = pkgs.fetchFromGitHub {
      owner = "fastapi-users";
      repo = pname;
      rev = "v${version}";
      hash = "sha256-PzcO6GNzi7BN3FZU3Eu6FxJdzqhaBVt2nIst3OYQrPQ=";
    };

    preBuild =
      let
        sed = "sed -i -E";
      in
      ''
        ${sed} '/dynamic =/d' ./pyproject.toml
        ${sed} 's#(\[project\])#\1\nversion = "${version}"#g' ./pyproject.toml
      '';

    pythonImportsCheck = [
      "fastapi_users"
    ];

    nativeBuildInputs = [
      hatch-vcs
      hatchling
    ];

    nativeCheckInputs = [
      pytestCheckHook
      asgi-lifespan
      pytest-asyncio
      pytest-mock
      redis
    ];

    propagatedBuildInputs = [
      bcrypt
      cryptography
      fastapi
      httpx-oauth
      makefun
      passlib
      pyjwt
      python-multipart
      typing-extensions
    ];

    meta = with lib; {
      description = "Ready-to-use and customizable users management for FastAPI";
      homepage = "https://github.com/fastapi-users/fastapi-users";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  ormar-postgres-extensions = buildPythonPackage rec {
    pname = "ormar-postgres-extensions";
    version = "2.3.0";

    format = "setuptools";
    src = pkgs.fetchFromGitHub {
      owner = "tophat";
      repo = pname;
      rev = "v${version}";
      hash = "sha256-s4+H8RwZbtBzZ+jLZweC1fPPkRtgEiFTXwWOrNEBClM=";
    };

    preBuild = ''
      substituteInPlace ./setup.py --replace 'psycopg2-binary' 'psycopg2'
    '';

    pythonImportsCheck = [
      "ormar_postgres_extensions"
    ];

    SETUPTOOLS_SCM_PRETEND_VERSION = version;

    nativeBuildInputs = [
      setuptools-scm
    ];

    nativeCheckInputs = [
      pytestCheckHook
      pytest-asyncio
    ];

    propagatedBuildInputs = [
      asyncpg
      ormar
      psycopg2
      pydantic
      sqlalchemy
    ];

    doCheck = false;

    meta = with lib; {
      description = "Extensions to the Ormar ORM to support PostgreSQL specific types";
      homepage = "https://github.com/tophat/ormar-postgres-extensions";
      license = licenses.asl20;
    };
  };

  vbuild = buildPythonPackage rec {
    pname = "vbuild";
    version = "0.8.1";
    format = "pyproject";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-uf+QcfphAJVj6TXt3qT98UlMcZQShfBf1XZI9z3Bnsw=";
    };

    postPatch = ''
      substituteInPlace ./pyproject.toml --replace "poetry.masonry.api" "poetry.core.masonry.api"
    '';

    nativeBuildInputs = [
      poetry-core
    ];

    propagatedBuildInputs = [
      pscript
    ];

    pythonImportsCheck = [ "vbuild" ];

    meta = with lib; {
      description = "A simple module to extract html/script/style from a vuejs '.vue' file (can minimize/es2015 compliant js) ... just py2 or py3, NO nodejs";
      homepage = "https://github.com/manatlan/vbuild";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  fastapi-socketio = buildPythonPackage rec {
    pname = "fastapi-socketio";
    version = "0.0.10";
    format = "setuptools";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-IC+bMZ8BAAHL0RFOySoNnrX1ypMW6uX9QaYIjaCBJyc=";
    };

    propagatedBuildInputs = [
      fastapi
      python-socketio
    ];

    passthru.optional-dependencies = {
      test = [
        pytest
      ];
    };

    doCheck = false;

    pythonImportsCheck = [ "fastapi_socketio" ];

    meta = with lib; {
      description = "Easily integrate socket.io with your FastAPI app";
      homepage = "https://github.com/pyropy/fastapi-socketio";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  nicegui = buildPythonPackage rec {
    pname = "nicegui";
    version = "1.2.17";
    format = "pyproject";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-aOCOY2A+l2i706hHgS5bjBGUsl2GrfG30JxJM5frKgo=";
    };

    postPatch = ''
      substituteInPlace ./pyproject.toml \
        --replace 'watchfiles = "^0.18.1"' 'watchfiles = ">0.18.1"'
    '';

    nativeBuildInputs = [
      poetry-core
      setuptools
    ];

    propagatedBuildInputs = [
      aiofiles
      fastapi
      fastapi-socketio
      httptools
      importlib-metadata
      jinja2
      markdown2
      matplotlib
      orjson
      plotly
      pygments
      python-dotenv
      python-multipart
      pywebview
      typing-extensions
      uvicorn
      uvloop
      vbuild
      watchfiles
      websockets
    ];

    pythonImportsCheck = [ "nicegui" ];

    meta = with lib; {
      description = "Create web-based interfaces with Python. The nice way";
      homepage = "https://github.com/zauberzeug/nicegui";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };
}
