final: prev:
let
  inherit (final) buildPythonPackage fetchPypi;
  inherit (final) poetry-core;
  inherit (final.lib) licenses maintainers;
  inherit (final.pkgs) fetchFromGitHub rustPlatform autoPatchelfHook bash;
in
rec {
  systemdunitparser = buildPythonPackage rec {
    pname = "systemdunitparser";
    version = "0.2";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-GgcqTlX8VXOCPgqRBJcWTbltnhZkiw9UDVRs1Vkd6Q4=";
    };

    nativeBuildInputs = with final; [
      setuptools
      wheel
    ];

    pythonImportsCheck = [ "SystemdUnitParser" ];

    meta = {
      description = "Parser to read and create unit files for systemd";
      homepage = "https://pypi.org/project/systemdunitparser/";
      license = licenses.gpl3Only;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  systemdlint = buildPythonPackage rec {
    pname = "systemdlint";
    version = "1.3.0";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-iJqWXL1lKc6CY3TRH2GB5CarmEYhSJdNeJCWO/28MOA=";
    };

    nativeBuildInputs = with final;[
      setuptools
      wheel
    ];

    propagatedBuildInputs = with final;[
      anytree
      systemdunitparser
    ];

    pythonImportsCheck = [ "systemdlint" ];

    meta = {
      description = "Systemd Unitfile Linter";
      homepage = "https://pypi.org/project/systemdlint/";
      maintainers = with maintainers; [ jpetrucciani ];
      mainProgram = "systemdlint";
    };
  };

  tesla-py = buildPythonPackage rec {
    pname = "tesla-py";
    version = "2.9.0";
    format = "setuptools";

    src = fetchPypi {
      pname = "TeslaPy";
      inherit version;
      hash = "sha256-8k7l8aYK+7DNzoZJeIJl9mAtagzVGqfWyTPVLzv8V1c=";
    };

    propagatedBuildInputs = with final; [
      requests
      requests-oauthlib
      websocket-client
    ];

    pythonImportsCheck = [ "teslapy" ];

    meta = {
      description = "A Python module to use the Tesla Motors Owner API";
      homepage = "https://github.com/tdorssers/TeslaPy";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  osrsreboxed = buildPythonPackage {
    pname = "osrsreboxed";
    version = "2.3.5";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "0xNeffarion";
      repo = "osrsreboxed-db";
      rev = "93346b7678d1cf741a00a67f9ed802eb88639dc2";
      hash = "sha256-4eyXlTIOrcbm2ZZ7s5OCKbnag4Gi1dX1DLFVQQtuEOc=";
    };

    preBuild = ''
      sed -i '/dataclasses/d' ./pyproject.toml
    '';

    propagatedBuildInputs = [
      poetry-core
    ];

    meta = {
      description = "A complete and up-to-date database of Old School Runescape (OSRS) items";
      homepage = "https://github.com/0xNeffarion/osrsreboxed-db";
    };
  };

  falconn = buildPythonPackage rec {
    pname = "falconn";
    version = "1.3.1";

    src = fetchFromGitHub {
      owner = "falconn-lib";
      repo = pname;
      rev = "v${version}";
      hash = "sha256-kz4w3uW3Y45ov7g86MPA3x2WlvBP8EKLVhqeHDKiemk=";
    };
    nativeBuildInputs = with final; [ pkgs.eigen ];
    propagatedBuildInputs = with final; [ numpy ];
    postPatch = ''
      sed -i -E 's#(cd FALCONN\-\*)#\1\/#g' ./Makefile
      make python_package
    '';
    preBuild = ''
      cd ./python_package/dist/FALCONN-*/
    '';
    pythonImportsCheck = [
      "falconn"
    ];
    meta = {
      description = "";
      homepage = "https://github.com/FALCONN-LIB/FALCONN";
      changelog = "https://github.com/FALCONN-LIB/FALCONN/releases/tag/v${version}";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  starred = buildPythonPackage rec {
    pname = "starred";
    version = "4.2.0";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "maguowei";
      repo = pname;
      rev = "v${version}";
      hash = "sha256-ugseXFiDQXLCg9wImpLCPmRJp31/OI8VuxxYD4JJ8mg=";
    };

    propagatedBuildInputs = with final; [
      aiohttp
      click
      github3_py
      gql
      poetry-core
      requests
    ];

    pythonCheckImports = [
      "starred"
    ];

    meta = {
      description = "Create your own Awesome List by GitHub stars";
      homepage = "https://github.com/maguowei/starred";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  milli = buildPythonPackage rec {
    pname = "milli";
    version = "1.1.1";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "AlexAltea";
      repo = "milli-py";
      rev = "v${version}";
      hash = "sha256-l8WS8B7w57RFYppDsl/6QAOA32m+xO/zs5JV1qBzfJ0=";
      fetchSubmodules = true;
    };

    cargoDeps = rustPlatform.importCargoLock {
      lockFile = "${src}/Cargo.lock";
      outputHashes = {
        "heed-0.12.5" = "sha256-atkKiK8rzqji47tJvUzbIXMw8U1uddHkHakPuEUvmFg=";
        "lmdb-rkv-sys-0.15.1" = "sha256-zLHTprwF7aa+2jaD7dGYmOZpJYFijMTb4I3ODflNUII=";
      };
    };
    sourceRoot = "";

    pythonImportsCheck = [
      "milli"
    ];

    buildInputs = with final; [
      pkgs.libiconv
    ];

    nativeBuildInputs = with final; [
      setuptools-rust
    ] ++ (with rustPlatform; [
      cargoSetupHook
      maturinBuildHook
      rust.cargo
      rust.rustc
    ]);

    meta = {
      description = "Python bindings for Milli, the embeddable Rust-based search engine powering Meilisearch";
      homepage = "https://github.com/AlexAltea/milli-py";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  speechrecognition = buildPythonPackage rec {
    pname = "speech_recognition";
    version = "3.9.0";

    format = "setuptools";
    src = fetchFromGitHub {
      owner = "Uberi";
      repo = pname;
      rev = version;
      hash = "sha256-FsiAa+cQbomFkRvoFscceVBJUW3mW6EyiizfFfqB/u8=";
    };

    doCheck = false;
    propagatedBuildInputs = with final; [
      requests
      soundfile
      google-cloud-speech
      openai-whisper
      pkgs.flac
    ];

    pythonCheckImports = [
      "speech_recognition"
    ];

    meta = {
      description = "Speech recognition module for Python, supporting several engines and APIs, online and offline";
      homepage = "https://github.com/Uberi/speech_recognition";
      license = licenses.bsd3;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  roadmapper = buildPythonPackage rec {
    pname = "roadmapper";
    version = "1.2.0";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-Sb3gomE5LDrxRM1U/QkrSQ2IemJ5Xhab4l4Ty6grNyM=";
    };

    nativeBuildInputs = with final; [
      setuptools
    ];

    propagatedBuildInputs = with final; [
      pillow
      python-dateutil
    ];

    pythonImportsCheck = [ "roadmapper" ];

    meta = {
      description = "Roadmapper. A Roadmap-as-Code (RaC) python library for generating a roadmap by using python code";
      homepage = "https://github.com/csgoh/roadmapper";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  pixoo = buildPythonPackage {
    pname = "pixoo";
    version = "0.6.0";
    format = "setuptools";

    src = fetchFromGitHub {
      owner = "SomethingWithComputers";
      repo = "pixoo";
      rev = "dc477493125dd2f57081e997fc1bb95e800dfee8";
      hash = "sha256-EDdwP8TBaHNbjcXS6QwN4PrtH3+4kWgxfqd0E4dZT8U=";
    };

    postPatch = let sed = "sed -i -E"; in ''
      ${sed} 's#(requests)\~\=(2.28.1)#\1>=\2#g' ./setup.py
      ${sed} 's#(Pillow)\~\=(9.2.0)#\1>=\2#g' ./setup.py
    '';

    propagatedBuildInputs = with final; [
      pillow
      requests
      tkinter
    ];

    pythonImportsCheck = [ "pixoo" ];

    meta = {
      description = "A library to help you make the most out of your Pixoo 64 (and hopefully soon other Wi-Fi enabled Pixoos";
      homepage = "https://github.com/SomethingWithComputers/pixoo";
      license = with licenses; [ ];
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  kaleido =
    let
      pname = "kaleido";
      version = "0.2.1";
      format = "wheel";
      dists = {
        aarch64-darwin = {
          dist = "macosx_11_0_arm64";
          hash = "01bwg2fdlhjbgf0ka2b17r614vcacpv0w97f6badamq3f4gmv6mv";
        };
        aarch64-linux = {
          dist = "manylinux2014_aarch64";
          hash = "0ajinsc7ylm8r1paiy3y4cmmry7v44kf85wwkm3ck0l09j21jn44";
        };
        x86_64-darwin = {
          dist = "macosx_10_11_x86_64";
          hash = "19s9a1w1afmqfvz96404yl797qfdpb9z2wrzhkrfpah0zzkp6vya";
        };
        x86_64-linux = {
          dist = "manylinux1_x86_64";
          hash = "1a63pnalnd5zzdy7c2pysv9pnf1w03hlazcz1ajqz3y7y4dwy8da";
        };
      };
      wheelUrl = dist: "${repo}/releases/download/v${version}/kaleido-${version}-py2.py3-none-${dist}.whl";
      repo = "https://github.com/plotly/Kaleido";
      src =
        let d = dists.${final.stdenv.hostPlatform.system} or (throw "Unsupported system: ${final.stdenv.hostPlatform.system}");
        in
        builtins.fetchurl {
          url = wheelUrl d.dist;
          sha256 = d.hash;
        };
    in
    buildPythonPackage {
      inherit pname src version format;
      nativeBuildInputs = [ autoPatchelfHook ];
      propagatedBuildInputs = [ ];
      pythonImportsCheck = [ "kaleido" ];
      postInstall = ''
        sed -i -E '1s#!/bin/bash#!${bash}/bin/bash#' $out/${final.python.sitePackages}/kaleido/executable/kaleido
      '';
      meta = {
        description = "cross-platform library for generating static images for web-based visualization libraries";
        homepage = repo;
        license = licenses.mit;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };

  coolname = buildPythonPackage rec {
    pname = "coolname";
    version = "2.2.0";
    format = "setuptools";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-bF1XMXWRBEeefKGVqbZPeQCsW+rUAYPAkyPH0L6edcc=";
    };

    pythonImportsCheck = [ "coolname" ];

    meta = {
      description = "Random name and slug generator";
      homepage = "https://github.com/alexanderlukanin13/coolname";
      license = licenses.bsd2;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  poetry2setup = buildPythonPackage rec {
    pname = "poetry2setup";
    version = "1.1.0";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-h1kVePwLaOFxYmHF8+9+1DbNwOEXTmKaNt5CRMJFvus=";
    };

    nativeBuildInputs = [
      poetry-core
    ];

    propagatedBuildInputs = [
      poetry-core
    ];

    pythonImportsCheck = [ "poetry2setup" ];

    meta = {
      description = "Convert python-poetry to setup.py";
      homepage = "https://github.com/abersheeran/poetry2setup";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  gaffe = buildPythonPackage rec {
    pname = "gaffe";
    version = "0.2.0";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-GUiwERbRfjgcQEFcfc1nmcSJS9uA/382vqrVD8aY89A=";
    };

    nativeBuildInputs = with final; [
      setuptools
    ];

    pythonImportsCheck = [ "gaffe" ];

    meta = {
      description = "Simple structured exceptions for python";
      homepage = "https://github.com/kodemore/gaffe";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  chili = buildPythonPackage rec {
    pname = "chili";
    version = "2.4.0";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-9wLfVoihy299YIUsTQL2uZojqjwzY9puI1EgUN8GBZ8=";
    };

    nativeBuildInputs = with final; [
      setuptools
    ];

    propagatedBuildInputs = with final; [
      gaffe
      typing-extensions
    ];

    pythonImportsCheck = [ "chili" ];

    meta = {
      description = "Serialise/deserialise almost any object";
      homepage = "https://github.com/kodemore/chili";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  yagmail = buildPythonPackage rec {
    pname = "yagmail";
    version = "0.15.293";

    src = fetchPypi {
      inherit pname version;
      sha256 = "15jjb00z89ck82q50g82xl6gv5r1snb91k0296hj4gpnlk6x1s24";
    };

    propagatedBuildInputs = with final; [ premailer ];

    meta = {
      description = "Yet Another GMAIL client";
      homepage = "https://github.com/kootenpv/yagmail";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  itomate = buildPythonPackage rec {
    pname = "itomate";
    version = "0.3.9";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "kamranahmedse";
      repo = pname;
      rev = "refs/tags/${version}";
      hash = "sha256-kZyYfZ8x/mDtYM8+7H3outrgdomCilMDRbf7jFmPkz0=";
    };

    nativeBuildInputs = with final;[
      setuptools
      wheel
    ];

    propagatedBuildInputs = with final;[
      iterm2
      pyyaml
    ];

    pythonImportsCheck = [ "itomate" ];

    meta = {
      description = "Automate your iTerm layouts and workflows";
      homepage = "https://github.com/kamranahmedse/itomate";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  recurrent = buildPythonPackage {
    pname = "recurrent";
    version = "0.4.1";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "kvh";
      repo = "recurrent";
      rev = "13fb7ac7e0060937e5f7e4e13a644a3e2b6f7021";
      hash = "sha256-I1FRmyJjs6We7qeCcyJlcFlUVQfjYUNHKj80KO0E7tk=";
    };

    propagatedBuildInputs = with final; [
      parsedatetime
    ];

    nativeBuildInputs = with final; [
      setuptools
      wheel
    ];

    pythonImportsCheck = [ "recurrent" ];

    meta = {
      description = "Natural language parsing of dates and recurring events";
      homepage = "https://github.com/kvh/recurrent";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  python-logging-loki = buildPythonPackage rec {
    pname = "python-logging-loki";
    version = "0.3.1";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "GreyZmeem";
      repo = "python-logging-loki";
      rev = "v${version}";
      hash = "sha256-1qHuv+xzATo11au+QAhD1lHcLJtnVKZDdQDGohHUhiI=";
    };

    nativeBuildInputs = with final; [
      setuptools
      wheel
    ];
    propagatedBuildInputs = with final; [
      requests
      rfc3339
    ];

    pythonImportsCheck = [ "logging_loki" ];

    meta = {
      description = "Python logging handler for Loki";
      homepage = "https://github.com/GreyZmeem/python-logging-loki";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  uhttp = buildPythonPackage {
    pname = "uhttp";
    version = "unstable-2023-12-09";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "0x67757300";
      repo = "uHTTP";
      rev = "312fc01049c6795a3684516f7e9418c2f11e7157";
      hash = "sha256-V8WiZVV7oGVj6bi1lPZ2fixZuqnGIdF8EZ3QZBDFZMk=";
    };

    nativeBuildInputs = with final; [
      poetry-core
    ];

    pythonImportsCheck = [ "uhttp" ];

    meta = {
      description = "Pythonic web development";
      homepage = "https://github.com/0x67757300/uHTTP";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  pypiserver-pluggable-backends = buildPythonPackage rec {
    pname = "pypiserver";
    version = "2.0.1";
    format = "setuptools";

    disabled = final.pythonOlder "3.7";

    src = fetchFromGitHub {
      owner = "estheruary";
      repo = "pypiserver-pluggable-backends";
      rev = "14f8182a5647437b72f6fd874d85b46ff099de44";
      hash = "sha256-EzkcJB7OtcaZDkzzvAbHKQohx98nhGrStgJVylD+G+0=";
    };

    nativeBuildInputs = with final; [
      setuptools
      setuptools-git
      wheel
    ];

    propagatedBuildInputs = with final; [
      pip
      setuptools
    ];

    passthru.optional-dependencies = with final; {
      passlib = [
        passlib
      ];
      cache = [
        watchdog
      ];
    };

    __darwinAllowLocalNetworking = true;

    # Tests need these permissions in order to use the FSEvents API on macOS.
    sandboxProfile = ''
      (allow mach-lookup (global-name "com.apple.FSEvents"))
    '';

    preCheck = ''
      export HOME=$TMPDIR
    '';

    nativeCheckInputs = with final; [
      pip
      pytestCheckHook
      setuptools
      twine
      webtest
    ] ++ lib.flatten (builtins.attrValues passthru.optional-dependencies);

    disabledTests = [
      # Fails to install the package
      "test_hash_algos"
      "test_pip_install_authed_succeeds"
      "test_pip_install_open_succeeds"
    ];

    disabledTestPaths = [
      # Test requires docker service running
      "docker/test_docker.py"
    ];

    pythonImportsCheck = [
      "pypiserver"
    ];

    meta = {
      description = "fork of a Minimal PyPI server for use with pip/easy_install";
      homepage = "https://github.com/estheruary/pypiserver-pluggable-backends";
      changelog = "https://github.com/estheruary/pypiserver-pluggable-backends/releases/tag/v${version}";
      license = with licenses; [ mit zlib ];
      maintainers = with maintainers; [ austinbutler ];
    };
  };

  pypiserver-backend-s3 = buildPythonPackage {
    pname = "pypiserver-backend-s3";
    version = "unstable-2023-08-24";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "estheruary";
      repo = "pypiserver-backend-s3";
      rev = "c7331c0df40c8881a2ffb3b9755e378c91b436c1";
      hash = "sha256-elItLLeN/v8ooDk8qedlqSGDHyZbwEr3Ze2e6idmDCM=";
    };

    nativeBuildInputs = with final; [
      pythonRelaxDepsHook
      setuptools
      setuptools-scm
      wheel
    ];

    pythonRelaxDeps = [
      "boto3"
    ];

    propagatedBuildInputs = with final; [
      boto3
    ];

    pythonImportsCheck = [ "pypiserver_backend_s3" ];

    meta = {
      description = "A pypiserver backend for storing packages directly to S3 (using boto3";
      homepage = "https://github.com/estheruary/pypiserver-backend-s3";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  horology = buildPythonPackage rec {
    pname = "horology";
    version = "1.4.0";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "mjmikulski";
      repo = "horology";
      rev = "v${version}";
      hash = "sha256-ZUcJax+cV9Lyn6oEGLqDRM2SAo/81BncH4KfT1+K9dw=";
    };

    nativeBuildInputs = with final; [
      poetry-core
    ];

    pythonImportsCheck = [ "horology" ];

    meta = {
      description = "Timing functions, contexts and for-loops";
      homepage = "https://github.com/mjmikulski/horology";
      changelog = "https://github.com/mjmikulski/horology/blob/${src.rev}/CHANGELOG.md";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  findblas = buildPythonPackage {
    pname = "findblas";
    version = "unstable-2024-01-13";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "david-cortes";
      repo = "findblas";
      rev = "29c29ec13d6e89ee977e87554aeef219c5db2552";
      hash = "sha256-VMiys4pa3X/uN5yJK4vBuigGObJeamXPipEjz3jZ6jo=";
    };

    postPatch =
      let
        BLAS = "${prev.pkgs.blas}/lib";
        BLAS_DEV = "${prev.pkgs.blas.dev}/include";
        find_blas = ''"${BLAS}", "libblas.so", "${BLAS_DEV}", "cblas.h", ["HAS_OPENBLAS"]'';
      in
      ''
        sed -i -E 's#\#\# Possible file names for each library in different OSes#return ${find_blas}#g' ./findblas/__init__.py
      '';

    nativeBuildInputs = with prev; [
      setuptools
      wheel
    ];

    pythonImportsCheck = [ "findblas" ];

    meta = {
      description = "Python module for finding available BLAS libraries in the system and linking wrapped C/C++ or FORTRAN code to it";
      homepage = "https://github.com/david-cortes/findblas";
      license = licenses.bsd2;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  mesop =
    buildPythonPackage rec {
      pname = "mesop";
      version = "0.7.2";
      format = "wheel";

      src = fetchPypi {
        inherit pname version;
        format = "wheel";
        python = "py3";
        dist = "py3";
        platform = "any";
        hash = "sha256-yZnen4/zwE1KDe75/uWbkXMuUCilU+6cqk10OEsydlU=";
      };

      propagatedBuildInputs = with final; [
        absl-py
        flask
        gunicorn
        libcst
        markdown
        protobuf
        pydantic
        watchdog
        werkzeug
      ];

      pythonImportsCheck = [ "mesop" ];

      meta = {
        description = "UI framework that allows you to rapidly build web apps like demos and internal apps";
        homepage = "https://github.com/google/mesop";
        license = licenses.asl20;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };

  shandy-sqlfmt = buildPythonPackage rec {
    pname = "shandy-sqlfmt";
    version = "0.21.3";
    pyproject = true;

    src = fetchPypi {
      pname = "shandy_sqlfmt";
      inherit version;
      hash = "sha256-UAqIoTNYVDKuz3dhlkITubdWq/1vM/XVPgUtLh0FhNo=";
    };

    nativeBuildInputs = [
      poetry-core
    ];

    propagatedBuildInputs = with final; [
      click
      importlib-metadata
      jinja2
      platformdirs
      tomli
      tqdm
    ];

    passthru.optional-dependencies = with final; {
      jinjafmt = [
        black
      ];
      sqlfmt_primer = [
        gitpython
      ];
    };

    pythonImportsCheck = [ "sqlfmt" ];

    meta = {
      description = "Sqlfmt formats your dbt SQL files so you don't have to";
      homepage = "https://pypi.org/project/shandy-sqlfmt/";
      license = licenses.asl20;
      mainProgram = "sqlfmt";
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  textual-fastdatatable = buildPythonPackage rec {
    pname = "textual-fastdatatable";
    version = "0.7.1";
    pyproject = true;

    src = fetchPypi {
      pname = "textual_fastdatatable";
      inherit version;
      hash = "sha256-Atkp3ddV59I5NuqAkMVJCQgW6eymPMFKBqwqgqVWt2M=";
    };

    nativeBuildInputs = [
      poetry-core
    ];

    propagatedBuildInputs = with final; [
      pyarrow
      pytz
      textual
      tzdata
    ];

    pythonImportsCheck = [ "textual_fastdatatable" ];

    meta = {
      description = "A performance-focused reimplementation of Textual's DataTable widget, with a pluggable data storage backend";
      homepage = "https://pypi.org/project/textual-fastdatatable/";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  textual-textarea = buildPythonPackage rec {
    pname = "textual-textarea";
    version = "0.13.0";
    pyproject = true;

    src = fetchPypi {
      pname = "textual_textarea";
      inherit version;
      hash = "sha256-xCzwGMZ0AHirZDwXok2DqKlBXPssntpqs7hDk6Qim9c=";
    };

    nativeBuildInputs = with final; [
      poetry-core
      pythonRelaxDepsHook
    ];

    pythonRelaxDeps = [
      "textual"
    ];

    propagatedBuildInputs = with final; [
      pyperclip
      textual
    ];

    pythonImportsCheck = [ "textual_textarea" ];

    meta = {
      description = "A text area (multi-line input) with syntax highlighting for Textual";
      homepage = "https://pypi.org/project/textual-textarea/";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  harlequin-mysql = buildPythonPackage rec {
    pname = "harlequin-mysql";
    version = "0.2.0";
    pyproject = true;

    src = fetchPypi {
      pname = "harlequin_mysql";
      inherit version;
      hash = "sha256-8YTtlcCXd6nb9BEM1axe4G/VsnX7HjABFQCARxPXIEs=";
    };

    nativeBuildInputs = with final; [
      poetry-core
      pythonRelaxDepsHook
    ];

    pythonRelaxDeps = [
      "mysql-connector-python"
    ];

    propagatedBuildInputs = with final; [
      harlequin
      mysql-connector
    ];

    pythonImportsCheck = [ "harlequin_mysql" ];

    meta = {
      description = "A Harlequin adapter for MySQL";
      homepage = "https://pypi.org/project/harlequin-mysql/";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  harlequin-postgres = buildPythonPackage rec {
    pname = "harlequin-postgres";
    version = "0.2.2";
    pyproject = true;

    src = fetchPypi {
      pname = "harlequin_postgres";
      inherit version;
      hash = "sha256-IF8ueqYjwaG9I1S4+h04sz4pYpIxgxaFhspGiPsay4E=";
    };

    nativeBuildInputs = [
      poetry-core
    ];

    dontCheckRuntimeDeps = true;

    propagatedBuildInputs = with final; [
      harlequin
      psycopg2
    ];

    pythonImportsCheck = [ "harlequin_postgres" ];

    meta = {
      description = "A Harlequin adapter for Postgres";
      homepage = "https://pypi.org/project/harlequin-postgres/";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  harlequin-odbc = buildPythonPackage rec {
    pname = "harlequin-odbc";
    version = "0.1.1";
    pyproject = true;

    src = fetchPypi {
      pname = "harlequin_odbc";
      inherit version;
      hash = "sha256-vrK1eDbM2yG0+ksVHizW/BuUb0+RTrIz3l3rwsCJIM8=";
    };

    nativeBuildInputs = [
      poetry-core
    ];

    propagatedBuildInputs = with final; [
      harlequin
      pyodbc
    ];

    pythonImportsCheck = [ "harlequin_odbc" ];

    meta = {
      description = "A Harlequin adapter for ODBC drivers";
      homepage = "https://pypi.org/project/harlequin-odbc/";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  harlequin = buildPythonPackage rec {
    pname = "harlequin";
    version = "1.21.0";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-wglcEjkGegLUIPaYAMPugH+qID1zjPf1Ht3rc7eE6FI=";
    };

    nativeBuildInputs = with final; [
      poetry-core
      pythonRelaxDepsHook
    ];

    pythonRelaxDeps = [
      "textual"
    ];
    propagatedBuildInputs = with final; [
      click
      duckdb
      importlib-metadata
      numpy
      platformdirs
      questionary
      rich-click
      shandy-sqlfmt
      textual
      textual-fastdatatable
      textual-textarea
      tomli
      tomlkit
      # adapters we like?
      boto3
    ];

    passthru.optional-dependencies = with final; {
      adbc = [
        harlequin-adbc
      ];
      bigquery = [
        harlequin-bigquery
      ];
      cassandra = [
        harlequin-cassandra
      ];
      databricks = [
        harlequin-databricks
      ];
      mysql = [
        harlequin-mysql
      ];
      nebulagraph = [
        harlequin-nebulagraph
      ];
      odbc = [
        harlequin-odbc
      ];
      postgres = [
        harlequin-postgres
      ];
      s3 = [
        boto3
      ];
      trino = [
        harlequin-trino
      ];
    };

    pythonImportsCheck = [ "harlequin" ];

    meta = {
      description = "The SQL IDE for Your Terminal";
      homepage = "https://pypi.org/project/harlequin/";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };
}
