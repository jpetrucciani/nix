final: prev:
let
  inherit (final) buildPythonPackage fetchPypi;
  inherit (final.lib) licenses maintainers;
  inherit (final.pkgs) fetchFromGitHub;
in
rec {
  asgi-lifespan = buildPythonPackage rec {
    pname = "asgi-lifespan";
    version = "2.0.0";

    format = "setuptools";
    src = fetchFromGitHub {
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

    nativeCheckInputs = with final; [
      pytestCheckHook
      pytest-asyncio
      starlette
      trio
    ];

    propagatedBuildInputs = with final; [
      sniffio
    ];

    meta = {
      description = "Programmatic startup/shutdown of ASGI apps";
      homepage = "https://github.com/florimondmanca/asgi-lifespan-db";
      license = licenses.mit;
    };
  };

  httpx-oauth = buildPythonPackage rec {
    pname = "httpx-oauth";
    version = "0.11.0";
    pyproject = true;

    src = fetchFromGitHub {
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

    nativeBuildInputs = with final; [
      hatch-vcs
      hatchling
    ];

    nativeCheckInputs = with final; [
      pytestCheckHook
      pytest-asyncio
      pytest-mock
      fastapi
      respx
    ];

    propagatedBuildInputs = with final; [
      httpx
    ];

    meta = {
      description = "";
      homepage = "https://github.com/frankie567/httpx-oauth";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  fastapi-users = buildPythonPackage rec {
    pname = "fastapi-users";
    version = "10.4.0";
    pyproject = true;

    src = fetchFromGitHub {
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

    nativeBuildInputs = with final; [
      hatch-vcs
      hatchling
    ];

    nativeCheckInputs = with final; [
      pytestCheckHook
      asgi-lifespan
      pytest-asyncio
      pytest-mock
      redis
    ];

    propagatedBuildInputs = with final; [
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

    meta = {
      description = "Ready-to-use and customizable users management for FastAPI";
      homepage = "https://github.com/fastapi-users/fastapi-users";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  ormar-postgres-extensions = buildPythonPackage rec {
    pname = "ormar-postgres-extensions";
    version = "2.9.0";

    format = "setuptools";
    src = fetchFromGitHub {
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

    nativeBuildInputs = with final; [
      setuptools-scm
    ];

    nativeCheckInputs = with final; [
      pytestCheckHook
      pytest-asyncio
    ];

    propagatedBuildInputs = with final; [
      asyncpg
      ormar
      psycopg2
      pydantic
      sqlalchemy
    ];

    doCheck = false;

    meta = {
      description = "Extensions to the Ormar ORM to support PostgreSQL specific types";
      homepage = "https://github.com/tophat/ormar-postgres-extensions";
      license = licenses.asl20;
    };
  };

  vbuild = buildPythonPackage rec {
    pname = "vbuild";
    version = "0.8.2";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-JwzZB4NJ2QffrmwOY2SlpedMuGGDu1CTYT8SoYtDX6k=";
    };

    postPatch = ''
      sed -i -E 's#(poetry)>=0.12#\1-core#g' ./pyproject.toml
      substituteInPlace ./pyproject.toml --replace "poetry.masonry.api" "poetry.core.masonry.api"
    '';

    nativeBuildInputs = with final; [
      poetry-core
    ];

    propagatedBuildInputs = with final; [
      pscript
    ];

    pythonImportsCheck = [ "vbuild" ];

    meta = {
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

    propagatedBuildInputs = with final; [
      fastapi
      python-socketio
    ];

    passthru.optional-dependencies = with final; {
      test = [
        pytest
      ];
    };

    doCheck = false;

    pythonImportsCheck = [ "fastapi_socketio" ];

    meta = {
      description = "Easily integrate socket.io with your FastAPI app";
      homepage = "https://github.com/pyropy/fastapi-socketio";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  wait-for2 = buildPythonPackage rec {
    pname = "wait-for2";
    version = "0.3.2";
    pyproject = true;

    src = fetchPypi {
      pname = "wait_for2";
      inherit version;
      hash = "sha256-k4YwJtw180cRBOz33h9KCzH0yLEqIkHA1u4m3MDCCSo=";
    };

    build-system = with final; [
      setuptools
      wheel
    ];

    pythonImportsCheck = [
      "wait_for2"
    ];

    meta = {
      description = "Asyncio wait_for that can handle simultaneous cancellation and future completion";
      homepage = "https://pypi.org/project/wait-for2";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  nicegui = buildPythonPackage rec {
    pname = "nicegui";
    version = "2.21.0";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-HWd0SyupAhIbo24JVNPkkiA0pjRWcMXS4y5hcktLzVo=";
    };

    postPatch = ''
      sed -i -E 's#(setuptools)>=30.3.0,<50#\1#g' ./pyproject.toml
    '';

    nativeBuildInputs = with final; [
      pythonRelaxDepsHook
      poetry-core
      setuptools
    ];

    pythonRelaxDeps = [
      "aiohttp"
      "certifi"
      "docutils"
      "fastapi"
      "h11"
      "httpx"
      "jinja2"
      "orjson"
      "python-multipart"
      "requests"
      "starlette"
      "uvicorn"
      "watchfiles"
    ];

    propagatedBuildInputs = with final; [
      aiofiles
      aiohttp
      colorama
      docutils
      fastapi
      fastapi-socketio
      httptools
      httpx
      ifaddr
      importlib-metadata
      itsdangerous
      jinja2
      markdown2
      matplotlib
      orjson
      plotly
      pygments
      python-dotenv
      python-magic
      python-multipart
      pywebview
      requests
      typing-extensions
      urllib3
      uvicorn
      uvloop
      vbuild
      wait-for2
      watchfiles
      websockets
    ];

    pythonImportsCheck = [ "nicegui" ];

    meta = {
      description = "Create web-based interfaces with Python. The nice way";
      homepage = "https://github.com/zauberzeug/nicegui";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };
}
