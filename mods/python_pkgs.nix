let
  pynixifyOverlay =
    final: prev: {
      python310 = prev.python310.override { inherit packageOverrides; };
      python311 = prev.python311.override { inherit packageOverrides; };
    };

  remove = e: builtins.filter (x: x != e);

  packageOverrides = final: prev: with final; {
    inherit (prev.stdenv) isDarwin isAarch64 isNixOS;
    isM1 = isDarwin && isAarch64;
    isOldMac = isDarwin && !isAarch64;

    twisted = if isM1 then prev.twisted.overrideAttrs (_: { doInstallCheck = false; }) else prev.twisted;
    pyopenssl = if isM1 then prev.pyopenssl.overrideAttrs (_: { meta.broken = false; }) else prev.pyopenssl;
    pycurl = if isM1 then prev.pycurl.overrideAttrs (_: { doInstallCheck = false; }) else prev.pycurl;

    # my packages
    archives = buildPythonPackage rec {
      pname = "archives";
      version = "0.12";

      src = fetchPypi {
        inherit pname version;
        sha256 = "10frsfmbd8cc8dv3dayfd68msk8ah0kvlr2yyx5y7l1vrmcsgxy8";
      };

      propagatedBuildInputs = [ click typed-ast radon ];

      meta = with lib; {
        description = "a new way to do python code documentation";
        homepage = "https://github.com/jpetrucciani/archives.git";
      };
    };

    # requirements for other packages
    radon = buildPythonPackage rec {
      pname = "radon";
      version = "5.1.0";

      src = fetchPypi {
        inherit pname version;
        sha256 = "1vmf56zsf3paa1jadjcjghiv2kxwiismyayq42ggnqpqwm98f7fb";
      };

      propagatedBuildInputs = [ mando colorama future ];

      doCheck = false;

      meta = with lib; {
        description = "Code Metrics in Python";
        homepage = "https://radon.readthedocs.org/";
      };
    };

    mando = buildPythonPackage rec {
      pname = "mando";
      version = "0.6.4";

      src = fetchPypi {
        inherit pname version;
        sha256 = "0q6rl085q1hw1wic52pqfndr0x3nirbxnhqj9akdm5zhq2fv3zkr";
      };

      propagatedBuildInputs = [ six ];

      doCheck = false;

      meta = with lib; {
        description = "Create Python CLI apps with little to no effort at all!";
        homepage = "https://mando.readthedocs.org/";
      };
    };

    # type annotations
    boto3-stubs = buildPythonPackage rec {
      pname = "boto3-stubs";
      version = "1.20.35";

      src = fetchPypi {
        inherit pname version;
        sha256 = "1nnd8jjakbcfjsfwn0w7i8mkqj7zji7x2vzmgklbrh3hw10ig95p";
      };

      propagatedBuildInputs = [ botocore-stubs ];
      checkInputs = [
        boto3
      ];
      pythonImportsCheck = [
        "boto3-stubs"
      ];

      meta = with lib; {
        description =
          "Type annotations for boto3 1.20.35, generated by mypy-boto3-builder 6.3.1";
        homepage = "https://github.com/vemel/mypy_boto3_builder";
      };
    };

    botocore-stubs = buildPythonPackage rec {
      pname = "botocore-stubs";
      version = "1.24.6";

      src = fetchPypi {
        inherit pname version;
        sha256 = "093zsj2wk7xw89yvs7w88z9w3811vkpgfv4q3wk9j6gd6n3hr1pw";
      };

      pythonImportsCheck = [
        "botocore-stubs"
      ];

      meta = with lib; {
        description =
          "Type annotations for botocore 1.24.6 generated with mypy-boto3-builder 7.1.2";
        homepage = "https://github.com/vemel/mypy_boto3_builder";
      };
    };

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


    notion-client = buildPythonPackage rec {
      pname = "notion-client";
      version = "0.9.0";

      src = fetchPypi {
        inherit pname version;
        sha256 = "004vx0fv7v12r18m1np1hjx9qnxgdk6aajsjhchvz0fyl2588f3l";
      };

      propagatedBuildInputs = [ httpx ];

      doCheck = false;

      pythonImportsCheck = [
        "notion_client"
      ];

      meta = with lib; {
        description = "Python client for the official Notion API";
        homepage = "https://github.com/ramnes/notion-sdk-py";
      };
    };

    mitmproxy2swagger = buildPythonPackage rec {
      pname = "mitmproxy2swagger";
      version = "0.4.2";

      src = fetchPypi {
        inherit version;
        pname = "mitmproxy2swagger";
        sha256 = "sha256-VTbHa+Dv0DD6t/xjYXGFnc4lA78XCUdYpVRIhWETqe4=";
      };

      propagatedBuildInputs = [
        setuptools
        asgiref
        blinker
        brotli
        certifi
        click
        cryptography
        flask
        h11
        h2
        hyperframe
        kaitaistruct
        ldap3
        msgpack
        passlib
        protobuf
        publicsuffix2
        pyopenssl
        pyparsing
        pyperclip
        ruamel-yaml
        sortedcontainers
        tornado
        urwid
        wsproto
        zstandard
        colorama
        flask
        mitmproxy
        markupsafe
      ];

      doCheck = false;
    };

    uncompyle6 = buildPythonPackage rec {
      pname = "uncompyle6";
      version = "3.8.0";

      src = fetchPypi {
        inherit pname version;
        sha256 = "053hh6mmllzwl7ndlf8fkiizr3yp6h4j4zhqg0z1zz3dixhk61k2";
      };

      propagatedBuildInputs = [ spark_parser xdis ];

      doCheck = false;
      pythonImportsCheck = [ "uncompyle6" ];

      meta = with lib; {
        description = "Python cross-version byte-code decompiler";
        homepage = "https://github.com/rocky/python-uncompyle6/";
      };
    };

    decompyle3 = buildPythonPackage rec {
      pname = "decompyle3";
      version = "3.9.0";

      src = fetchPypi {
        inherit pname version;
        sha256 = "0c55zm1d7bi1lpvw1z0vvdvfkaqhfkcf40494khd2kcv23wcnji2";
      };

      propagatedBuildInputs = [ click spark_parser xdis ];

      doCheck = false;

      meta = with lib; {
        description = "Python cross-version byte-code decompiler";
        homepage = "https://github.com/rocky/python-decompile3/";
      };
    };

    pyrasite = buildPythonPackage rec {
      pname = "pyrasite";
      version = "2.0";

      src = fetchPypi {
        inherit pname version;
        sha256 = "1kvc3xqdxn5y1jk554kaa83wi9xvkf70mil8csj0179p0ima7xz5";
      };

      doCheck = false;
      pythonImportsCheck = [ "pyrasite" ];

      meta = with lib; {
        description = "Inject code into a running Python process";
        homepage = "http://pyrasite.com";
      };
    };

    pyinstaller = buildPythonPackage rec {
      pname = "pyinstaller";
      version = "5.3";

      src = fetchPypi {
        inherit pname version;
        sha256 = "1dypgw9qax9bs8rfsybysp2fk3rfgq3wqxxl4d5xbr06k1kd8wfy";
      };
      propagatedBuildInputs = [
        (buildPythonPackage rec {
          pname = "altgraph";
          version = "0.17.2";

          src = fetchPypi {
            inherit pname version;
            sha256 = "0n4ihdwzp42gfnqzwlbwq43wdjz4yqwn8scfp2rrfzdlc69jdwpb";
          };

          doCheck = false;

          meta = with lib; {
            description = "Python graph (network) package";
            homepage = "https://altgraph.readthedocs.io";
          };
        })
        (buildPythonPackage rec {
          pname = "pyinstaller-hooks-contrib";
          version = "2022.8";

          src = fetchPypi {
            inherit pname version;
            sha256 = "0mns2cicr6p1zplkp3jhj0imj1clmszy11g432lwdjc20b2hy8f4";
          };

          buildInputs = [ setuptools ];

          doCheck = false;

          meta = with lib; { };
        })
        setuptools
        pkgs.zlib
      ];
      doCheck = false;

      meta = with lib; { };
    };

    aiomcache = buildPythonPackage rec {
      pname = "aiomcache";
      version = "0.7.0";

      src = fetchPypi {
        inherit pname version;
        sha256 = "007mbdk566n5r50xg8xhgvc92x082h6svdyja78dmcmlr4xx6gx7";
      };

      checkInputs = [
        docker
        python-memcached
        pytestCheckHook
      ];
      doCheck = false;

      pythonImportsCheck = [ "aiomcache" ];

      meta = with lib; {
        description = "Minimal pure python memcached client";
        homepage = "https://github.com/aio-libs/aiomcache/";
      };
    };

    aiohttp-security = buildPythonPackage rec {
      pname = "aiohttp-security";
      version = "0.4.0";

      src = fetchPypi {
        inherit pname version;
        sha256 = "01clxi9zdbj3pysd7hph9kll1q98mdp0yqm3vz195qsl0havpm20";
      };

      checkInputs = [
        pyjwt
        pytestCheckHook
      ];

      doCheck = false;

      propagatedBuildInputs = [ aiohttp aiohttp-session ];
      pythonImportsCheck = [ "aiohttp_security" ];

      meta = with lib; {
        description = "security for aiohttp.web";
        homepage = "https://github.com/aio-libs/aiohttp_security/";
      };
    };

    aiohttp-session = buildPythonPackage rec {
      pname = "aiohttp-session";
      version = "2.11.0";

      src = fetchPypi {
        inherit pname version;
        sha256 = "1i2x07jln9162rv2c6hi2d28ba8w0ycv1izn7sac81ba1xh3kpqg";
      };

      checkInputs = [
        aiomcache
        aioredis
        docker
        pytestCheckHook
      ];

      disabledTestPaths = [
        "tests/test_redis_storage.py"
        "tests/test_nacl_storage.py"
        "tests/test_path_domain.py"
        "tests/test_response_types.py"
        "tests/test_memcached_storage.py"
        "tests/test_encrypted_cookie_storage.py"
        "tests/test_cookie_storage.py"
        "tests/test_http_exception.py"
        "tests/test_abstract_storage.py"
      ];

      propagatedBuildInputs = [ aiohttp ];
      pythonImportsCheck = [ "aiohttp_session" ];

      meta = with lib; {
        description = "sessions for aiohttp.web";
        homepage = "https://github.com/aio-libs/aiohttp_session/";
      };
    };

    osrsreboxed = buildPythonPackage rec {
      pname = "osrsreboxed";
      version = "2.3.5";

      format = "pyproject";
      src = pkgs.fetchFromGitHub {
        owner = "0xNeffarion";
        repo = "osrsreboxed-db";
        rev = "93346b7678d1cf741a00a67f9ed802eb88639dc2";
        sha256 = "sha256-4eyXlTIOrcbm2ZZ7s5OCKbnag4Gi1dX1DLFVQQtuEOc=";
      };

      preBuild = ''
        ${pkgs.gnused}/bin/sed -i '/dataclasses/d' ./pyproject.toml
      '';

      propagatedBuildInputs = [
        poetry
      ];

      meta = with lib; {
        description = "A complete and up-to-date database of Old School Runescape (OSRS) items";
        homepage = "https://github.com/0xNeffarion/osrsreboxed-db";
      };
    };

    refurb = buildPythonPackage rec {
      pname = "refurb";
      version = "1.4.0";

      format = "pyproject";
      src = pkgs.fetchFromGitHub {
        owner = "dosisod";
        repo = "refurb";
        rev = "v${version}";
        sha256 = "sha256-YLgKW2PKI9F+vwtFGi3T0Eb/rJY3sXwE/JPNQ2ityCg=";
      };

      propagatedBuildInputs = [
        mypy
        poetry
      ];

      meta = with lib; {
        description = "Tool for refurbishing and modernizing Python codebases";
        homepage = "https://github.com/dosisod/refurb";
      };
    };

    ruff = buildPythonPackage rec {
      pname = "ruff";
      version = "0.0.92";

      format = "pyproject";

      src = pkgs.fetchFromGitHub {
        owner = "charliermarsh";
        repo = "ruff";
        rev = "v${version}";
        sha256 = "sha256-PTlLxFtp1IdHobhwN4zoxVQgDDc8CAG4q5YD2DqQ7oM=";
      };

      cargoDeps = pkgs.rustPlatform.fetchCargoTarball {
        inherit src sourceRoot;
        name = "${pname}-${version}";
        sha256 = "sha256-bhOT0kecoJL/DqOkYVgKZojV2U+nX0/ckWCPb8Zchu4=";
      };
      sourceRoot = "";

      nativeBuildInputs = [ setuptools-rust ] ++ (with pkgs.rustPlatform; [
        cargoSetupHook
        maturinBuildHook
        rust.cargo
        rust.rustc
      ]);
    };

  };
in
pynixifyOverlay
