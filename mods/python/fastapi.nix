final: prev:
let
  inherit (final) buildPythonPackage fetchPypi;
  inherit (final.lib) licenses maintainers;
  inherit (final.pkgs) fetchFromGitHub;
in
{
  fastapi-users = buildPythonPackage rec {
    pname = "fastapi-users";
    version = "10.4.0";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "fastapi-users";
      repo = pname;
      rev = "v${version}";
      hash = "sha256-PzcO6GNzi7BN3FZU3Eu6FxJdzqhaBVt2nIst3OYQrPQ=";
    };

    preBuild =
      let
        sed = "sed -i -E";
      in
      ''
        ${sed} '/dynamic =/d' ./pyproject.toml
        ${sed} 's#(\[project\])#\1\nversion = "${version}"#g' ./pyproject.toml
      '';

    pythonImportsCheck = [
      "fastapi_users"
    ];

    nativeBuildInputs = with final; [
      hatch-vcs
      hatchling
    ];

    nativeCheckInputs = with final; [
      pytestCheckHook
      asgi-lifespan
      pytest-asyncio
      pytest-mock
      redis
    ];

    propagatedBuildInputs = with final; [
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

    meta = {
      description = "Ready-to-use and customizable users management for FastAPI";
      homepage = "https://github.com/fastapi-users/fastapi-users";
      license = licenses.mit;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  fastapi-socketio = buildPythonPackage rec {
    pname = "fastapi-socketio";
    version = "0.0.10";
    format = "setuptools";

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-IC+bMZ8BAAHL0RFOySoNnrX1ypMW6uX9QaYIjaCBJyc=";
    };

    propagatedBuildInputs = with final; [
      fastapi
      python-socketio
    ];

    passthru.optional-dependencies = with final; {
      test = [
        pytest
      ];
    };

    doCheck = false;

    pythonImportsCheck = [ "fastapi_socketio" ];

    meta = {
      description = "Easily integrate socket.io with your FastAPI app";
      homepage = "https://github.com/pyropy/fastapi-socketio";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };

  wait-for2 = buildPythonPackage rec {
    pname = "wait-for2";
    version = "0.3.2";
    pyproject = true;

    src = fetchPypi {
      pname = "wait_for2";
      inherit version;
      hash = "sha256-k4YwJtw180cRBOz33h9KCzH0yLEqIkHA1u4m3MDCCSo=";
    };

    build-system = with final; [
      setuptools
      wheel
    ];

    pythonImportsCheck = [
      "wait_for2"
    ];

    meta = {
      description = "Asyncio wait_for that can handle simultaneous cancellation and future completion";
      homepage = "https://pypi.org/project/wait-for2";
      license = licenses.asl20;
      maintainers = with maintainers; [ jpetrucciani ];
    };
  };
}
