(final: prev: with prev; {
  tesla-py = buildPythonPackage rec {
    pname = "tesla-py";
    version = "2.8.0";
    format = "setuptools";

    src = fetchPypi {
      pname = "TeslaPy";
      inherit version;
      hash = "sha256-+LdOKxqFjvhkWzhsKkujt9tYQb8yqi3LgBO48JtT7NM=";
    };

    propagatedBuildInputs = [
      requests
      requests-oauthlib
      websocket-client
    ];

    pythonImportsCheck = [ "teslapy" ];

    meta = with lib; {
      description = "A Python module to use the Tesla Motors Owner API";
      homepage = "https://github.com/tdorssers/TeslaPy";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

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
    version = "1.1.1";

    format = "pyproject";
    src = pkgs.fetchFromGitHub {
      owner = "AlexAltea";
      repo = "milli-py";
      rev = "v${version}";
      hash = "sha256-l8WS8B7w57RFYppDsl/6QAOA32m+xO/zs5JV1qBzfJ0=";
      fetchSubmodules = true;
    };

    cargoDeps = pkgs.rustPlatform.importCargoLock {
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

  roadmapper = buildPythonPackage rec {
    pname = "roadmapper";
    version = "1.2.0";
    format = "pyproject";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-Sb3gomE5LDrxRM1U/QkrSQ2IemJ5Xhab4l4Ty6grNyM=";
    };

    nativeBuildInputs = [
      setuptools
    ];

    propagatedBuildInputs = [
      pillow
      python-dateutil
    ];

    pythonImportsCheck = [ "roadmapper" ];

    meta = with lib; {
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

    src = pkgs.fetchFromGitHub {
      owner = "SomethingWithComputers";
      repo = "pixoo";
      rev = "dc477493125dd2f57081e997fc1bb95e800dfee8";
      hash = "sha256-EDdwP8TBaHNbjcXS6QwN4PrtH3+4kWgxfqd0E4dZT8U=";
    };

    postPatch = let sed = "${pkgs.gnused}/bin/sed -i -E"; in ''
      ${sed} 's#(requests)\~\=(2.28.1)#\1>=\2#g' ./setup.py
      ${sed} 's#(Pillow)\~\=(9.2.0)#\1>=\2#g' ./setup.py
    '';

    propagatedBuildInputs = [
      pillow
      requests
      tkinter
    ];

    pythonImportsCheck = [ "pixoo" ];

    meta = with lib; {
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
        let d = dists.${prev.stdenv.hostPlatform.system} or (throw "Unsupported system: ${prev.stdenv.hostPlatform.system}");
        in
        builtins.fetchurl {
          url = wheelUrl d.dist;
          sha256 = d.hash;
        };
    in
    buildPythonPackage {
      inherit pname src version format;
      nativeBuildInputs = [ pkgs.autoPatchelfHook ];
      propagatedBuildInputs = [ ];
      pythonImportsCheck = [ "kaleido" ];
      postInstall = ''
        ${pkgs.gnused}/bin/sed -i -E '1s#!/bin/bash#!${pkgs.bash}/bin/bash#' $out/${prev.python.sitePackages}/kaleido/executable/kaleido
      '';
      meta = with lib; {
        description = "cross-platform library for generating static images for web-based visualization libraries";
        homepage = repo;
        license = licenses.mit;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };
})
