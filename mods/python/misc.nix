final: prev: prev.hax.pythonPackageOverlay
  (self: super: with super; {
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
        homepage = "https://github.com/jpetrucciani/archives";
        license = licenses.mit;
        maintainers = with maintainers; [ jpetrucciani ];
      };
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

    osrsreboxed = buildPythonPackage {
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
        poetry-core
      ];

      meta = with lib; {
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
        sha256 = "sha256-kz4w3uW3Y45ov7g86MPA3x2WlvBP8EKLVhqeHDKiemk=";
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
        sha256 = "sha256-ugseXFiDQXLCg9wImpLCPmRJp31/OI8VuxxYD4JJ8mg=";
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
  })
  [ "python310" "python311" ]
  final
  prev
