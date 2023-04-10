final: prev: with prev; rec {
  pynecone =
    let
      sqlalchemy2-stubs = buildPythonPackage rec {
        pname = "sqlalchemy2-stubs";
        version = "0.0.2a32";

        disabled = pythonOlder "3.7";
        src = fetchPypi {
          inherit pname version;
          sha256 = "sha256-Kiz6tx01rGO/Ia2EHYYQzZOjvUxlYoSMU4+pdVhcJzk=";
        };

        propagatedBuildInputs = [ typing-extensions ];
        meta = with lib; { };
      };
      sqlmodel = buildPythonPackage rec {
        pname = "sqlmodel";
        version = "0.0.8";
        format = "pyproject";

        disabled = pythonOlder "3.7";
        src = pkgs.fetchFromGitHub {
          owner = "tiangolo";
          repo = "sqlmodel";
          rev = version;
          sha256 = "sha256-HASWDm64vZsOnK+cL2/G9xiTbsBD2RoILXrigZMQncQ=";
        };

        pythonImportsCheck = [
          "sqlmodel"
        ];

        preBuild =
          let
            sed = "${pkgs.gnused}/bin/sed -i -E";
          in
          ''
            ${sed} 's#,<=1.4.41##g' ./pyproject.toml
            ${sed} 's#(version = )"0"#\1"${version}"#g' ./pyproject.toml
          '';

        propagatedBuildInputs = [
          poetry-core
          pydantic
          sqlalchemy
          sqlalchemy2-stubs
        ];

        meta = with lib; { };
      };
      typer = buildPythonPackage rec {
        pname = "typer";
        version = "0.4.2";

        format = "flit";
        src = fetchPypi {
          inherit pname version;
          sha256 = "00zcc8gk37q7j5y0ycawf6699mp5fyk6paavid3p7paj05n1q9mq";
        };

        propagatedBuildInputs = [
          click
        ];
        meta = with lib; { };
      };
    in
    buildPythonPackage rec {
      pname = "pynecone";
      version = "0.1.20";
      format = "pyproject";


      src = pkgs.fetchFromGitHub {
        owner = "pynecone-io";
        repo = pname;
        rev = "v${version}";
        sha256 = "sha256-I3+4p20shdqWSEmxTj7iN1zoKsxRG3x8HbhUkg2avV0=";
      };

      propagatedBuildInputs = [
        pkgs.nodejs-18_x
        cloudpickle
        fastapi
        gunicorn
        httpx
        plotly
        poetry-core
        psutil
        pydantic
        python-socketio
        redis
        rich
        uvicorn
        watchdog
        websockets
        # special
        sqlmodel
        typer
      ];

      preBuild =
        let
          sed = "${pkgs.gnused}/bin/sed -i -E";
        in
        ''
          ${sed} 's#BUN_PATH =.*#BUN_PATH = "${pkgs.bun}/bin/bun"#g' ./pynecone/constants.py
          ${sed} 's#(rich = )"\^12.6.0"#\1"\^13.0.0"#g' ./pyproject.toml
          ${sed} 's#(pydantic = )"1.10.2"#\1"1.10.4"#g' ./pyproject.toml
          ${sed} 's#(watchdog = )"\^2.3.1"#\1"\^2.2.1"#g' ./pyproject.toml
        '';

      pythonImportsCheck = [
        "pynecone"
      ];

      meta = with lib; {
        description = "Web apps in pure Python";
        homepage = "https://github.com/pynecone-io/pynecone";
        license = licenses.asl20;
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
    version = "0.3.0";

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
    version = "0.2.3";

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

  llama-cpp-python =
    let
      osSpecific = with pkgs.darwin.apple_sdk.frameworks; if pkgs.stdenv.isDarwin then [ Accelerate ] else [ ];
      llama-cpp-pin = pkgs.fetchFromGitHub {
        owner = "ggerganov";
        repo = "llama.cpp";
        rev = "180b693a47b6b825288ef9f2c39d24b6eea4eea6";
        hash = "sha256-omDUqS6ljFRg2jcT7S+isUda/0rS4gOQlOEl8qZWwVw=";
      };
    in
    buildPythonPackage rec {
      pname = "llama-cpp-python";
      version = "0.1.30";

      format = "pyproject";
      src = pkgs.fetchFromGitHub {
        owner = "abetlen";
        repo = pname;
        rev = "bc02ce353b29cf67ff66a31eee6c14c5ceff708c";
        hash = "sha256-CFP39qnG+AkYWszFaNZnh2vMhOBMRgZ46at/OMFmUiI=";
      };

      preConfigure = ''
        cp -r ${llama-cpp-pin}/. ./vendor/llama.cpp
        chmod -R +w ./vendor/llama.cpp
      '';
      preBuild = ''
        cd ..
      '';
      buildInputs = osSpecific;

      nativeBuildInputs = [
        prev.pkgs.cmake
        prev.pkgs.ninja
        poetry-core
        scikit-build
        setuptools
      ];

      propagatedBuildInputs = [
        typing-extensions
      ];

      pythonImportsCheck = [ "llama_cpp" ];

      meta = with lib; {
        description = "A Python wrapper for llama.cpp";
        homepage = "https://github.com/abetlen/llama-cpp-python";
        license = licenses.mit;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };


  geojson = prev.geojson.overridePythonAttrs {
    version = "2.5.0";
    src = fetchPypi {
      version = "2.5.0";
      pname = "geojson";
      hash = "sha256-bku3rOQiakXZyMixNIs/xDVAZYNZ+Tw/fgPvqfFfZYo=";
    };
    doCheck = false;
    pythonImportsCheck = [
      "geojson"
    ];
  };

  openapi-schema-pydantic = buildPythonPackage rec {
    pname = "openapi-schema-pydantic";
    version = "1.2.4";
    format = "pyproject";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-PiLPWLdKafdSzH5fFTf25EFkKC2ycAy7zTu5nd0GUZY=";
    };

    nativeBuildInputs = [
      setuptools
    ];

    propagatedBuildInputs = [
      pydantic
    ];

    pythonImportsCheck = [ "openapi_schema_pydantic" ];

    meta = with lib; {
      description = "OpenAPI (v3) specification schema as pydantic class";
      homepage = "https://pypi.org/project/openapi-schema-pydantic/1.2.4/";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  langchain = buildPythonPackage rec {
    pname = "langchain";
    version = "0.0.134";
    format = "pyproject";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-+5XEQ7xLxJq7PAfDiM4nxMWQ7903G00/wIJCjGkRE54=";
    };

    nativeBuildInputs = [
      poetry-core
    ];

    propagatedBuildInputs = [
      pyyaml
      (sqlalchemy.overridePythonAttrs {
        version = "1.4.42";
        src = fetchPypi {
          version = "1.4.42";
          pname = "SQLAlchemy";
          hash = "sha256-F35BkUxHbtHht3/QWWbqiMCUBT4XqFMDxM4Af4jv82M=";
        };
      })
      aiohttp
      dataclasses-json
      numpy
      openapi-schema-pydantic
      pydantic
      pyowm
      requests
      tenacity
    ];

    passthru.optional-dependencies = {
      all = [
        aleph-alpha-client
        anthropic
        beautifulsoup4
        cohere
        deeplake
        elasticsearch
        faiss-cpu
        google-api-python-client
        google-search-results
        huggingface-hub
        jina
        jinja2
        manifest-ml
        networkx
        nlpcloud
        nltk
        nomic
        openai
        opensearch-py
        pgvector
        pinecone-client
        psycopg2-binary
        pypdf
        qdrant-client
        redis
        sentence-transformers
        spacy
        tensorflow-text
        tiktoken
        torch
        transformers
        weaviate-client
        wikipedia
        wolframalpha
      ];
      llms = [
        anthropic
        cohere
        huggingface-hub
        manifest-ml
        nlpcloud
        openai
        torch
        transformers
      ];
    };

    pythonImportsCheck = [ "langchain" ];

    meta = with lib; {
      description = "Building applications with LLMs through composability";
      homepage = "https://pypi.org/project/langchain/0.0.125/";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };
}
