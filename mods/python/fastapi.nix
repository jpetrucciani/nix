final: prev: prev.hax.pythonPackageOverlay
  (self: super: with super; rec {

    asgi-lifespan = buildPythonPackage rec {
      pname = "asgi-lifespan";
      version = "2.0.0";

      format = "setuptools";
      src = pkgs.fetchFromGitHub {
        owner = "florimondmanca";
        repo = pname;
        rev = version;
        hash = "sha256-wKwvCuHupAxIGxW53vUpIxcA1yx4kpWDX/coiNk+3MI=";
      };


      pythonImportsCheck = [
        "asgi_lifespan"
      ];

      preCheck = ''
        cp ./setup.cfg ./setup.cfg.bak
        ${pkgs.gnused}/bin/sed '/addopts =/Q' ./setup.cfg.bak >./setup.cfg
      '';

      nativeCheckInputs = [
        pytestCheckHook
        pytest-asyncio
        starlette
        trio
      ];

      propagatedBuildInputs = [
        sniffio
      ];

      meta = with lib; {
        description = "Programmatic startup/shutdown of ASGI apps";
        homepage = "https://github.com/florimondmanca/asgi-lifespan-db";
        license = licenses.mit;
      };
    };

    httpx-oauth = buildPythonPackage rec {
      pname = "httpx-oauth";
      version = "0.11.0";

      format = "pyproject";
      src = pkgs.fetchFromGitHub {
        owner = "frankie567";
        repo = pname;
        rev = "v${version}";
        hash = "sha256-zmoGr60hEudra3Bgt2sd+aovpvXmvfNL/LAcgkDI678=";
      };

      preBuild =
        let
          sed = "${pkgs.gnused}/bin/sed -i -E";
        in
        ''
          ${sed} '/dynamic =/d' ./pyproject.toml
          ${sed} '/addopts =/d' ./pyproject.toml
          ${sed} 's#(\[project\])#\1\nversion = "${version}"#g' ./pyproject.toml
        '';

      pythonImportsCheck = [
        "httpx_oauth"
      ];

      nativeBuildInputs = [
        hatch-vcs
        hatchling
      ];

      nativeCheckInputs = [
        pytestCheckHook
        pytest-asyncio
        pytest-mock
        fastapi
        respx
      ];

      propagatedBuildInputs = [
        httpx
      ];

      meta = with lib; {
        description = "";
        homepage = "https://github.com/frankie567/httpx-oauth";
        license = licenses.mit;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };


    prometheus-fastapi-instrumentator = buildPythonPackage rec {
      pname = "prometheus-fastapi-instrumentator";
      version = "5.11.1";

      format = "pyproject";
      src = pkgs.fetchFromGitHub {
        owner = "trallnag";
        repo = pname;
        rev = "v${version}";
        hash = "sha256-OU/Q7BG0ud/e+FSQTrwzHCkBHMfnb3mzWj87ruRi9Y8=";
      };

      pythonImportsCheck = [
        "prometheus_fastapi_instrumentator"
      ];

      nativeBuildInputs = [
        poetry-core
      ];

      nativeCheckInputs = [
        pytestCheckHook
        requests
      ];

      disabledTestPaths = [
        "tests/test_instrumentator_multiple_apps.py"
      ];

      propagatedBuildInputs = [
        fastapi
        prometheus-client
      ];

      meta = with lib; {
        description = "Instrument your FastAPI app";
        homepage = "https://github.com/trallnag/prometheus-fastapi-instrumentator";
        license = licenses.isc;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };

    fastapi-users = buildPythonPackage rec {
      pname = "fastapi-users";
      version = "10.4.0";

      format = "pyproject";
      src = pkgs.fetchFromGitHub {
        owner = "fastapi-users";
        repo = pname;
        rev = "v${version}";
        hash = "sha256-PzcO6GNzi7BN3FZU3Eu6FxJdzqhaBVt2nIst3OYQrPQ=";
      };

      preBuild =
        let
          sed = "${pkgs.gnused}/bin/sed -i -E";
        in
        ''
          ${sed} '/dynamic =/d' ./pyproject.toml
          ${sed} 's#(\[project\])#\1\nversion = "${version}"#g' ./pyproject.toml
        '';

      pythonImportsCheck = [
        "fastapi_users"
      ];

      nativeBuildInputs = [
        hatch-vcs
        hatchling
      ];

      nativeCheckInputs = [
        pytestCheckHook
        asgi-lifespan
        pytest-asyncio
        pytest-mock
        redis
      ];

      propagatedBuildInputs = [
        bcrypt
        cryptography
        fastapi
        httpx-oauth
        makefun
        passlib
        pyjwt
        python-multipart
        typing-extensions
      ];

      meta = with lib; {
        description = "Ready-to-use and customizable users management for FastAPI";
        homepage = "https://github.com/fastapi-users/fastapi-users";
        license = licenses.mit;
        maintainers = with maintainers; [ jpetrucciani ];
      };
    };

  })
  [ "python310" "python311" ]
  final
  prev
