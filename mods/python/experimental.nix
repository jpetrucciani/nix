final: prev: with prev; rec {
  reflex =
    let
      relaxDeps = let _rm = dep: ''-e "/${dep} =/d"''; in deps: ''
        sed -i -E ${prev.lib.concatStringsSep " " (map _rm deps)} ./pyproject.toml
      '';
    in
    buildPythonPackage rec {
      pname = "reflex";
      version = "0.3.5";
      format = "pyproject";


      src = pkgs.fetchFromGitHub {
        owner = "reflex-dev";
        repo = pname;
        rev = "refs/tags/v${version}";
        sha256 = "sha256-pLAlv73O/nHyZYSsLav4igOS/IgTliWNaCSWGnGH1OI=";
      };

      propagatedBuildInputs = [
        pkgs.nodejs_20
        alembic
        cloudpickle
        fastapi
        gunicorn
        httpx
        platformdirs
        plotly
        poetry-core
        psutil
        pydantic
        python-dotenv
        python-socketio
        redis
        rich
        uvicorn
        watchdog
        watchfiles
        websockets
        # special
        sqlmodel
        starlette-admin
        typer
      ] ++ (lib.optionals stdenv.isLinux [ distro ]);

      postPatch = ''
        sed -i -E 's#(DEFAULT_PATH) =.*#\1 = "${pkgs.bun}/bin/bun"#g' ./reflex/constants/installer.py
        sed -i -E -z 's#(BIN_PATH)(.*)\n\)#\1 = "${pkgs.nodejs_20}/bin"#g' ./reflex/constants/installer.py
        ${relaxDeps [
          "alembic"
          "fastapi"
          "gunicorn"
          "httpx"
          "platformdirs"
          "python-dotenv"
          "python-multipart"
          "starlette-admin"
          "watchdog"
        ]}
      '';

      pythonImportsCheck = [ "reflex" ];

      meta = with lib; {
        description = "Web apps in pure Python";
        homepage = "https://github.com/reflex-dev/reflex";
        license = licenses.asl20;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };

  starlette-admin = buildPythonPackage rec {
    pname = "starlette-admin";
    version = "0.11.1";
    format = "pyproject";

    src = fetchPypi {
      pname = "starlette_admin";
      inherit version;
      hash = "sha256-VgihoOi3P7oLMgmwVA+9G+gWH9XoC7z9FoJ5Y/c+rFA=";
    };

    nativeBuildInputs = [
      hatchling
    ];

    propagatedBuildInputs = [
      jinja2
      python-multipart
      starlette
    ];

    passthru.optional-dependencies = {
      dev = [
        pre-commit
        uvicorn
      ];
      doc = [
        mkdocs
        mkdocs-material
        mkdocs-static-i18n
        mkdocstrings
      ];
      i18n = [
        babel
      ];
      test = [
        aiomysql
        aiosqlite
        arrow
        asyncpg
        backports-zoneinfo
        black
        colour
        coverage
        fasteners
        httpx
        itsdangerous
        mongoengine
        mypy
        odmantic
        passlib
        phonenumbers
        pillow
        psycopg2-binary
        pydantic
        pymysql
        pytest
        pytest-asyncio
        ruff
        sqlalchemy-file
        sqlalchemy-utils
        tinydb
      ];
    };

    pythonImportsCheck = [ "starlette_admin" ];

    meta = with lib; {
      description = "Fast, beautiful and extensible administrative interface framework for Starlette/FastApi applications";
      homepage = "https://github.com/jowilf/starlette-admin";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  # emmett
  emmett-rest = buildPythonPackage rec {
    pname = "rest";
    version = "1.4.5";
    format = "pyproject";

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
    format = "pyproject";

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
    format = "pyproject";

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
    format = "pyproject";

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
    version = "0.3.5";

    format = "pyproject";
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

  granian = buildPythonPackage rec {
    pname = "granian";
    version = "0.3.5";

    format = "pyproject";
    src = pkgs.fetchFromGitHub {
      owner = "emmett-framework";
      repo = pname;
      rev = "v${version}";
      sha256 = "sha256-2JnyO0wxkV49R/0wzDb/PnUWWHi3ckwK4nVe7dWeH1k=";
    };

    cargoDeps = pkgs.rustPlatform.fetchCargoTarball {
      inherit src sourceRoot;
      name = "${pname}-${version}";
      sha256 = "sha256-rRTOSyOQ7qWGipyug92KHVmvjS8cMSpnjxZigru86Yg=";
    };
    sourceRoot = "";

    preBuild = ''
      sed -i -E 's#typer\~=0.4.1#typer\~=0.6.1#' ./pyproject.toml
    '';

    propagatedBuildInputs = [
      typer
      uvloop
    ];

    pythonImportsCheck = [
      "granian"
    ];

    nativeBuildInputs = [
      setuptools-rust
      pkgs.installShellFiles
    ] ++ (with pkgs.rustPlatform; [
      cargoSetupHook
      maturinBuildHook
      rust.cargo
      rust.rustc
    ]);

    postInstall = ''
      installShellCompletion --cmd granian \
        --bash <($out/bin/granian --show-completion bash) \
        --fish <($out/bin/granian --show-completion fish) \
        --zsh  <($out/bin/granian --show-completion zsh)
    '';

    meta = with lib; {
      description = "A Rust HTTP server for Python applications";
      homepage = "https://github.com/emmett-framework/granian";
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
}
