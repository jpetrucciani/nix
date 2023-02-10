final: prev: prev.hax.pythonPackageOverlay
  (self: super: with super; {
    # mitmproxy2swagger = buildPythonPackage rec {
    #   pname = "mitmproxy2swagger";
    #   version = "0.4.2";

    #   src = fetchPypi {
    #     inherit version;
    #     pname = "mitmproxy2swagger";
    #     sha256 = "sha256-VTbHa+Dv0DD6t/xjYXGFnc4lA78XCUdYpVRIhWETqe4=";
    #   };

    #   propagatedBuildInputs = [
    #     setuptools
    #     asgiref
    #     blinker
    #     brotli
    #     certifi
    #     click
    #     cryptography
    #     flask
    #     h11
    #     h2
    #     hyperframe
    #     kaitaistruct
    #     ldap3
    #     msgpack
    #     passlib
    #     protobuf
    #     publicsuffix2
    #     pyopenssl
    #     pyparsing
    #     pyperclip
    #     ruamel-yaml
    #     sortedcontainers
    #     tornado
    #     urwid
    #     wsproto
    #     zstandard
    #     colorama
    #     flask
    #     mitmproxy
    #     markupsafe
    #   ];

    #   doCheck = false;
    # };

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

      meta = {
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

      meta = {
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

      meta = {
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

          meta = {
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

          meta = { };
        })
        setuptools
        pkgs.zlib
      ];
      doCheck = false;

      meta = { };
    };
  })
  [ "python310" "python311" ]
  final
  prev
