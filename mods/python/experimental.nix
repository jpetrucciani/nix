final: prev: with prev; rec {
  # emmett
  emmett-rest = buildPythonPackage rec {
    pname = "rest";
    version = "1.4.5";
    pyproject = true;

    disabled = pythonOlder "3.7";
    src = pkgs.fetchFromGitHub {
      owner = "emmett-framework";
      repo = pname;
      rev = "v${version}";
      sha256 = "sha256-9sWZSYQAY5Mmk8pkcYZoFEZ20g/MOEyatjTE8xwd1Ks=";
    };

    propagatedBuildInputs = [
      poetry-core
      pydantic
      emmett
    ];

    checkInputs = [
      pytestCheckHook
    ];

    doCheck = false;

    pythonImportsCheck = [
      "emmett_rest"
    ];

    meta = with lib; {
      description = "REST extension for Emmett framework";
      changelog = "https://github.com/emmett-framework/rest/blob/master/CHANGES.md";
      homepage = "https://github.com/emmett-framework/rest";
      license = licenses.bsd3;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  renoir = buildPythonPackage rec {
    pname = "renoir";
    version = "1.6.0";
    pyproject = true;

    disabled = pythonOlder "3.7";
    src = pkgs.fetchFromGitHub {
      owner = "emmett-framework";
      repo = pname;
      rev = "v${version}";
      sha256 = "sha256-PTmaOCkkKYsPTzD9m9T1IIew00OskZ/bXXvzcmVRWUA=";
    };

    propagatedBuildInputs = [
      poetry-core
      pyyaml
    ];

    checkInputs = [
      pytestCheckHook
    ];

    preBuild = ''
      mv ./pyproject.toml ./pyproject.bak
      ${yq}/bin/tomlq -yt 'del(.tool.poetry.include)' ./pyproject.bak > ./pyproject.toml
    '';

    pythonImportsCheck = [
      "renoir"
    ];

    meta = with lib; {
      description = "A templating engine designed with simplicity in mind";
      changelog = "https://github.com/emmett-framework/renoir/blob/master/CHANGES.md";
      homepage = "https://github.com/emmett-framework/renoir";
      license = licenses.bsd3;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  severus = buildPythonPackage rec {
    pname = "severus";
    version = "1.2.0";
    pyproject = true;

    disabled = pythonOlder "3.7";
    src = pkgs.fetchFromGitHub {
      owner = "emmett-framework";
      repo = pname;
      rev = "v${version}";
      sha256 = "sha256-JO9AGKqko2xKU8siKDkhCclWO6yqW9sSzFGpeQLSCXI=";
    };

    propagatedBuildInputs = [
      poetry-core
      pyyaml
    ];

    preBuild = ''
      sed -i -E 's#pyyaml = "\^5.3.1"#pyyaml = "\^6.0.0"#' ./pyproject.toml
      mv ./pyproject.toml ./pyproject.bak
      ${yq}/bin/tomlq -yt 'del(.tool.poetry.include)' ./pyproject.bak > ./pyproject.toml
    '';

    pythonImportsCheck = [
      "severus"
    ];

    checkInputs = [
      pytestCheckHook
    ];

    meta = with lib; {
      description = "An internationalization engine designed with simplicity in mind";
      changelog = "https://github.com/emmett-framework/severus/blob/master/CHANGES.md";
      homepage = "https://github.com/emmett-framework/severus";
      license = licenses.bsd3;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  emmett = buildPythonPackage rec {
    pname = "emmett";
    version = "2.4.13";
    pyproject = true;

    disabled = pythonOlder "3.7";
    src = pkgs.fetchFromGitHub {
      owner = "emmett-framework";
      repo = pname;
      rev = "v${version}";
      sha256 = "sha256-crKVQ1URCRztp7vMQKHxwDf5y72opKlPezW6LX/QXzU=";
    };

    propagatedBuildInputs = [
      click
      h11
      h2
      pendulum
      (pydal.overridePythonAttrs (_: {
        version = "17.3";
        src = pkgs.fetchFromGitHub {
          owner = "web2py";
          repo = "pydal";
          rev = "v17.03";
          sha256 = "sha256-ZxdWhdtZDMXf5oIjprVNS4iSLei4w/wtT/5cqMXbIXw=";
        };
      }))
      pyaes
      python-rapidjson
      pyyaml
      renoir
      severus
      uvicorn
      websockets
      httptools
      uvloop
    ];

    pythonImportsCheck = [
      "emmett"
    ];

    preBuild = ''
      sed -i -E 's#pyyaml = "\^5.4"#pyyaml = "\^6.0.0"#' ./pyproject.toml
      sed -i -E 's#uvicorn = "\~0.19.0"#uvicorn = "\~0.20.0"#' ./pyproject.toml
      sed -i -E 's#h2 = ">= 3.2.0\, < 4.1.0"#h2 = ">= 4.1.0"#' ./pyproject.toml
      mv ./pyproject.toml ./pyproject.bak
      ${yq}/bin/tomlq -yt 'del(.tool.poetry.include)' ./pyproject.bak > ./pyproject.toml
    '';

    checkInputs = [
      pytestCheckHook
    ];

    meta = with lib; {
      description = "The web framework for inventors";
      homepage = "https://emmett.sh";
      changelog = "https://github.com/emmett-framework/emmett/blob/master/CHANGES.md";
      license = licenses.bsd3;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  emmett-crypto = buildPythonPackage rec {
    pname = "emmett-crypto";
    version = "0.3.8";
    pyproject = true;

    src = pkgs.fetchFromGitHub {
      owner = "emmett-framework";
      repo = "crypto";
      rev = "v${version}";
      sha256 = "sha256-hPBcpno+cFKRNNnsT0YsReqW1XLTjqERmwhGHpqFa0Y=";
    };

    cargoDeps = pkgs.rustPlatform.fetchCargoTarball {
      inherit src sourceRoot;
      name = "${pname}-${version}";
      sha256 = "sha256-qL9lG0u1bnGhQ4RRqEhT8Ev81z7CcZJM0EpsVrjUe0c=";
    };
    sourceRoot = "";

    pythonImportsCheck = [
      "emmett_crypto"
    ];

    nativeBuildInputs = [
      setuptools-rust
    ] ++ (with pkgs.rustPlatform; [
      cargoSetupHook
      maturinBuildHook
      rust.cargo
      rust.rustc
    ]);

    meta = with lib; {
      description = "Cryptographic utilities for Emmett framework";
      homepage = "https://github.com/emmett-framework/crypto";
      changelog = "https://github.com/emmett-framework/crypto/blob/master/CHANGES.md";
      license = licenses.bsd3;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  icon-font-to-png = buildPythonPackage rec {
    pname = "icon-font-to-png";
    version = "0.4.1";

    format = "setuptools";
    src = pkgs.fetchFromGitHub {
      owner = "Pythonity";
      repo = pname;
      rev = "v${version}";
      hash = "sha256-6BK9LtI9Kr/rdQQidUtk4YCW5rZfvFzbDF4hkjoQYW8=";
    };

    propagatedBuildInputs = [
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
    src = pkgs.fetchFromGitHub {
      owner = "minimaxir";
      repo = pname;
      rev = "v${version}";
      hash = "sha256-WZRzT254JWhhaKYuiq9KMmTo1m5ywK0TzmaVJVeCt2k=";
    };

    propagatedBuildInputs = [
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
    src = pkgs.fetchFromGitHub {
      owner = "minimaxir";
      repo = pname;
      rev = "5ceceb8fa66e56a59ed7a833cd585df21869e3b9";
      hash = "sha256-Vq9oBdruldS4wURU1XbmfwXsjnVO/L1zRDhPU11OqsE=";
    };

    propagatedBuildInputs = [
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

    nativeBuildInputs = [
      setuptools
      wheel
    ];

    propagatedBuildInputs = [
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

    nativeBuildInputs = [
      pythonRelaxDepsHook
      setuptools
      wheel
    ];

    pythonRelaxDeps = [
      "fastcore"
    ];

    propagatedBuildInputs = [
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

    nativeBuildInputs = [
      setuptools
      wheel
      pythonRelaxDepsHook
    ];

    pythonRelaxDeps = [
      "fastcore"
      "uvicorn"
    ];

    propagatedBuildInputs = [
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

    passthru.optional-dependencies = {
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

    src = pkgs.fetchFromGitHub {
      owner = "canonical";
      repo = "maas";
      rev = version;
      hash = "sha256-39+b/cuLJfPyjz+07ppPhUNTZeRn8CfJ8viuZFM0i3A=";
      fetchSubmodules = true;
    };

    nativeBuildInputs = [
      setuptools
      wheel
    ];

    propagatedBuildInputs = [
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
