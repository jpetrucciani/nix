final: prev: prev.hax.pythonPackageOverlay
  (self: super: with super; {
    pynecone-io =
      let
        newStarlette = let version = "0.23.1"; in
          starlette.overridePythonAttrs (_: {
            inherit version;
            format = "pyproject";
            nativeBuildInputs = [
              hatchling
            ];
            src = pkgs.fetchFromGitHub {
              owner = "encode";
              repo = "starlette";
              rev = "refs/tags/${version}";
              hash = "sha256-LcFrdaRgFBqcdylCzNlewj/papsg/sZ1FMVxBDLvQWI=";
            };
            patches = [ ];
            checkInputs = [
              httpx
            ];
          });
        newFastapi = let version = "0.88.0"; in
          fastapi.overridePythonAttrs (_: {
            inherit version;
            src = pkgs.fetchFromGitHub {
              owner = "tiangolo";
              repo = "fastapi";
              rev = "refs/tags/${version}";
              hash = "sha256-2rjKmQcehqkL5OnmtLRTvsyUSpK2aUgyE9VLvz+oWNw=";
            };
            propagatedBuildInputs = [
              newStarlette
              newPydantic
            ];
            disabledTestPaths = _.disabledTestPaths ++ [ "tests/test_generate_unique_id_function.py" ];
          });
        newPydantic = let version = "1.10.2"; in
          (pydantic.override { withDocs = false; }).overridePythonAttrs (_: {
            inherit version;
            src = pkgs.fetchFromGitHub {
              owner = "pydantic";
              repo = "pydantic";
              rev = "refs/tags/v${version}";
              sha256 = "sha256-NQMnqcN2muQd6J4RtL5IcSO5OdQnIR28rmwCSWGfe14=";
            };
          });
        newRedis = let version = "4.4.0"; in
          redis.overridePythonAttrs (_: {
            inherit version;
            src = fetchPypi {
              inherit version;
              pname = "redis";
              sha256 = "sha256-e4yH0ZxF0/EnGxJIWNKlwTFgxOdNSDXignNAD6NNUig=";
            };
          });
        sqlalchemy2-stubs = buildPythonPackage rec {
          pname = "sqlalchemy2-stubs";
          version = "0.0.2a30";

          src = fetchPypi {
            inherit pname version;
            sha256 = "0qi5k8k1qv9i5khx3ylyhb52xra67gmiq4pmbwhp3r6b85kn1rx6";
          };

          propagatedBuildInputs = [ typing-extensions ];
          meta = with lib; { };
        };
        sqlmodel = buildPythonPackage rec {
          pname = "sqlmodel";
          version = "0.0.8";

          src = fetchPypi {
            inherit pname version;
            sha256 = "sha256-M3G00a1Z0v/QxTBYLCFAtsBrCQsyr5ucZBKYbXsRcDY=";
          };

          propagatedBuildInputs = [
            newPydantic
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
        version = "0.1.12";
        format = "pyproject";


        src = pkgs.fetchFromGitHub {
          owner = "pynecone-io";
          repo = "pynecone";
          rev = "v${version}";
          sha256 = "sha256-Vrhq6TratGfwA+WKf17k3z/8zNSRNhnpgubBUic457s=";
        };

        propagatedBuildInputs = [
          pkgs.nodejs-18_x
          gunicorn
          httpx
          plotly
          poetry-core
          rich
          uvicorn
          websockets
          # special
          sqlmodel
          typer
          newFastapi
          newPydantic
          newRedis
        ];

        preBuild = ''
          ${pkgs.gnused}/bin/sed -i -E 's#BUN_PATH =.*#BUN_PATH = "${pkgs.bun}/bin/bun"#g' ./pynecone/constants.py
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

  })
  [ "python310" "python311" ]
  final
  prev
