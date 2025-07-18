final: prev:
let
  inherit (final) buildPythonPackage fetchPypi;
  inherit (final.pkgs) fetchFromGitHub rustPlatform lib;
in
rec {
  ty = buildPythonPackage rec {
    pname = "ty";
    version = "0.0.1-alpha.15";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "astral-sh";
      repo = "ty";
      rev = "refs/tags/${version}";
      hash = "sha256-7aOFRrnj4WFTuQWcOgdSU3w9KWwRbpPj3K6g4y0JPo0=";
      fetchSubmodules = true;
    };

    build-system = [
      rustPlatform.maturinBuildHook
      rustPlatform.cargoSetupHook
    ];
    cargoRoot = "ruff";
    cargoDeps = rustPlatform.importCargoLock {
      lockFile = "${src}/ruff/Cargo.lock";
      outputHashes = {
        "lsp-types-0.95.1" = "sha256-8Oh299exWXVi6A39pALOISNfp8XBya8z+KT/Z7suRxQ=";
        "salsa-0.23.0" = "sha256-jVL/Y548jv8RJ1rgBdJcsGtwIsH2aLxBbgO4FZl78wc=";
      };
    };

    pythonImportsCheck = [ "ty" ];

    meta = {
      description = "An extremely fast Python type checker and language server, written in Rust";
      homepage = "https://github.com/astral-sh/ty";
      license = lib.licenses.mit;
      maintainers = with lib.maintainers; [ jpetrucciani ];
    };
  };

  icon-font-to-png = buildPythonPackage rec {
    pname = "icon-font-to-png";
    version = "0.4.1";

    format = "setuptools";
    src = fetchFromGitHub {
      owner = "Pythonity";
      repo = pname;
      rev = "v${version}";
      hash = "sha256-6BK9LtI9Kr/rdQQidUtk4YCW5rZfvFzbDF4hkjoQYW8=";
    };

    propagatedBuildInputs = with final; [
      pillow
      requests
      six
      tinycss
    ];

    meta = with lib; {
      description = "Python script (and library) for exporting icons from icon fonts (e.g. Font Awesome, Octicons) as PNG images";
      homepage = "https://github.com/Pythonity/icon-font-to-png";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  stylecloud = buildPythonPackage rec {
    pname = "stylecloud";
    version = "0.5.2";

    format = "setuptools";
    src = fetchFromGitHub {
      owner = "minimaxir";
      repo = pname;
      rev = "v${version}";
      hash = "sha256-WZRzT254JWhhaKYuiq9KMmTo1m5ywK0TzmaVJVeCt2k=";
    };

    propagatedBuildInputs = with final; [
      wordcloud
      icon-font-to-png
      palettable
      fire
      matplotlib
    ];

    meta = with lib; {
      description = "CLI to generate stylistic wordclouds, including gradients and icon shapes";
      homepage = "https://github.com/minimaxir/stylecloud";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  icon-image = buildPythonPackage rec {
    pname = "icon-image";
    version = "0.0.0";

    format = "setuptools";
    src = fetchFromGitHub {
      owner = "minimaxir";
      repo = pname;
      rev = "5ceceb8fa66e56a59ed7a833cd585df21869e3b9";
      hash = "sha256-Vq9oBdruldS4wURU1XbmfwXsjnVO/L1zRDhPU11OqsE=";
    };

    propagatedBuildInputs = with final; [
      pillow
      numpy
      icon-font-to-png
      fire
    ];

    preBuild = ''
      cat >./setup.py << EOF
      from setuptools import setup
      setup(
        name="icon-image",
        entry_points={"console_scripts": ["icon-image=icon_image:cli"]}
      )
      EOF
    '';

    meta = with lib; {
      description = "quickly generate a Font Awesome icon imposed on a background for steering AI image generation";
      homepage = "https://github.com/minimaxir/icon-image";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  sqlite-minutils = buildPythonPackage rec {
    pname = "sqlite-minutils";
    version = "3.36.0.post4";
    pyproject = true;

    src = fetchPypi {
      pname = "sqlite_minutils";
      inherit version;
      hash = "sha256-SkSt84IHluKwwks1mCxT5oejqV177b54WcSMzmYWg3o=";
    };

    nativeBuildInputs = with final; [
      setuptools
      wheel
    ];

    propagatedBuildInputs = with final; [
      fastcore
    ];

    pythonImportsCheck = [ "sqlite_minutils" ];

    meta = with lib; {
      description = "A fork of sqlite-utils with CLI etc removed";
      homepage = "https://pypi.org/project/sqlite-minutils/";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  fastlite = buildPythonPackage rec {
    pname = "fastlite";
    version = "0.0.8";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-qQz/ax74QgsXRIMCcrXqCPDnXGOtexXYwHe5f6ztQ9s=";
    };

    nativeBuildInputs = with final; [
      pythonRelaxDepsHook
      setuptools
      wheel
    ];

    pythonRelaxDeps = [
      "fastcore"
    ];

    propagatedBuildInputs = with final; [
      fastcore
      sqlite-minutils
    ];

    pythonImportsCheck = [ "fastlite" ];

    meta = with lib; {
      description = "A bit of extra usability for sqlite";
      homepage = "https://pypi.org/project/fastlite/";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  fasthtml = buildPythonPackage rec {
    pname = "python-fasthtml";
    version = "0.4.2";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-jn32w93V7RaZSxjmerJKCzTuxK0MVa6ZesVkiYQFTKA=";
    };

    nativeBuildInputs = with final; [
      setuptools
      wheel
      pythonRelaxDepsHook
    ];

    pythonRelaxDeps = [
      "fastcore"
      "uvicorn"
    ];

    propagatedBuildInputs = with final; [
      beautifulsoup4
      fastcore
      fastlite
      httpx
      itsdangerous
      oauthlib
      python-dateutil
      python-multipart
      starlette
      uvicorn
    ];

    passthru.optional-dependencies = with final;{
      dev = [
        ipython
        lxml
      ];
    };

    pythonImportsCheck = [ "fasthtml" ];

    meta = with lib; {
      description = "The fastest way to create an HTML app";
      homepage = "https://github.com/AnswerDotAI/fasthtml";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  maas = buildPythonPackage rec {
    pname = "maas";
    version = "3.5.0-beta1";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "canonical";
      repo = "maas";
      rev = version;
      hash = "sha256-39+b/cuLJfPyjz+07ppPhUNTZeRn8CfJ8viuZFM0i3A=";
      fetchSubmodules = true;
    };

    nativeBuildInputs = with final; [
      setuptools
      wheel
    ];

    propagatedBuildInputs = with final; [
      aiodns
      aiofiles
      aiohttp
      asyncpg
      bson
      fastapi
      httplib2
      hvac
      jsonschema
      lxml
      macaroonbakery
      markupsafe
      oauthlib
      paramiko
      pexpect
      psycopg2
      pyopenssl
      pytz
      pyyaml
      requests
      uvloop
    ];

    pythonImportsCheck = [ "maascli" ];

    meta = with lib; {
      description = "Official MAAS repository mirror (may be out of date). Development happens in Launchpad (https://git.launchpad.net/maas";
      homepage = "https://github.com/canonical/maas/";
      license = licenses.agpl3Only;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };
}
