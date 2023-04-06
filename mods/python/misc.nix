(final: prev: with prev; {
  osrsreboxed = buildPythonPackage {
    pname = "osrsreboxed";
    version = "2.3.5";

    format = "pyproject";
    src = pkgs.fetchFromGitHub {
      owner = "0xNeffarion";
      repo = "osrsreboxed-db";
      rev = "93346b7678d1cf741a00a67f9ed802eb88639dc2";
      hash = "sha256-4eyXlTIOrcbm2ZZ7s5OCKbnag4Gi1dX1DLFVQQtuEOc=";
    };

    preBuild = ''
      ${pkgs.gnused}/bin/sed -i '/dataclasses/d' ./pyproject.toml
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

    src = pkgs.fetchFromGitHub {
      owner = "falconn-lib";
      repo = pname;
      rev = "v${version}";
      hash = "sha256-kz4w3uW3Y45ov7g86MPA3x2WlvBP8EKLVhqeHDKiemk=";
    };
    nativeBuildInputs = [ pkgs.eigen ];
    propagatedBuildInputs = [
      numpy
    ];
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
    meta = with lib; {
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

    format = "pyproject";
    src = pkgs.fetchFromGitHub {
      owner = "maguowei";
      repo = pname;
      rev = "v${version}";
      hash = "sha256-ugseXFiDQXLCg9wImpLCPmRJp31/OI8VuxxYD4JJ8mg=";
    };

    propagatedBuildInputs = [
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

    meta = with lib; {
      description = "Create your own Awesome List by GitHub stars";
      homepage = "https://github.com/maguowei/starred";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  milli = buildPythonPackage rec {
    pname = "milli";
    version = "1.0.0";

    format = "pyproject";
    src = pkgs.fetchFromGitHub {
      owner = "AlexAltea";
      repo = "milli-py";
      rev = "4cbb103fa679d254332e98291af29350a8bab1cd";
      hash = "sha256-q9kc1WQIqYjLrCQFvku+YvvSYNruyhaRJP5Mwutujrg=";
      fetchSubmodules = true;
    };

    cargoDeps = pkgs.rustPlatform.fetchCargoTarball {
      inherit src sourceRoot;
      name = "${pname}-${version}";
      hash = "sha256-kunz3sjYCJoPdxdKPDofIy03e/u7wBeGuY0L9rrxQEM=";
    };
    sourceRoot = "";

    pythonImportsCheck = [
      "milli"
    ];

    buildInputs = [
      pkgs.libiconv
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
    src = pkgs.fetchFromGitHub {
      owner = "Uberi";
      repo = pname;
      rev = version;
      hash = "sha256-FsiAa+cQbomFkRvoFscceVBJUW3mW6EyiizfFfqB/u8=";
    };

    doCheck = false;
    propagatedBuildInputs = [
      requests
      soundfile
      google-cloud-speech
      openai-whisper
      pkgs.flac
    ];

    pythonCheckImports = [
      "speech_recognition"
    ];

    meta = with lib; {
      description = "Speech recognition module for Python, supporting several engines and APIs, online and offline";
      homepage = "https://github.com/Uberi/speech_recognition";
      license = licenses.bsd3;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

})
