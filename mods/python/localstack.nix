final: prev: prev.hax.pythonPackageOverlay
  (self: super: with super; {
    # quart = buildPythonPackage rec {
    #   pname = "quart";
    #   version = "0.17.0";

    #   format = "pyproject";
    #   src = pkgs.fetchFromGitHub {
    #     owner = "pallets";
    #     repo = pname;
    #     rev = version;
    #     hash = "sha256-xpMvCOFoSpuit+KnLs3iWwneK++mLgjD7E6vTUUMwaU=";
    #   };

    #   propagatedBuildInputs = [
    #     aiofiles
    #     asgiref
    #     blinker
    #     click
    #     hypercorn
    #     itsdangerous
    #     jinja2
    #     python-dotenv
    #     werkzeug
    #   ];

    #   preBuild =
    #     let
    #       sed = "${pkgs.gnused}/bin/sed -i -E";
    #     in
    #     ''
    #       ${sed} '/addopts =/d' ./pyproject.toml
    #     '';

    #   pythonImportsCheck = [
    #     "quart"
    #   ];

    #   nativeCheckInputs = [
    #     pytestCheckHook
    #     hypothesis
    #   ];

    #   nativeBuildInputs = [
    #     poetry-core
    #   ];

    #   doCheck = false;

    #   meta = with lib; {
    #     description = "";
    #     homepage = "https://github.com/pallets/quart";
    #     license = licenses.mit;
    #     maintainers = with maintainers; [ jpetrucciani ];
    #   };
    # };

    # readerwriterlock = buildPythonPackage {
    #   pname = "readerwriterlock";
    #   version = "0.0.0";

    #   format = "setuptools";
    #   src = pkgs.fetchFromGitHub {
    #     owner = "elarivie";
    #     repo = "pyReaderWriterLock";
    #     rev = "e7382855cdd46c9d54b2d697c48c00b8fd7e4c81";
    #     hash = "sha256-53LOAUzfiD61MNik+6XnyEslfK1jJkWDElnvIbgHqDU=";
    #   };

    #   propagatedBuildInputs = [
    #   ];

    #   pythonImportsCheck = [
    #     "readerwriterlock"
    #   ];

    #   nativeBuildInputs = [
    #     typing-extensions
    #   ];

    #   nativeCheckInputs = [
    #     pytestCheckHook
    #   ];

    #   # tests require time passing
    #   doCheck = false;

    #   meta = with lib; {
    #     description = "implementation of the Readers-writers problem";
    #     homepage = "https://github.com/elarivie/pyReaderWriterLock";
    #     license = licenses.mit;
    #     maintainers = with maintainers; [ jpetrucciani ];
    #   };
    # };

    # localstack-full = super.localstack.overridePythonAttrs (old: {
    #   propagatedBuildInputs = old.propagatedBuildInputs ++ (with super; [
    #     (boto.overridePythonAttrs (_: { doCheck = false; }))
    #     cbor2
    #     dnslib
    #     docker
    #     flask
    #     h11
    #     hypercorn
    #     moto
    #     pymongo
    #     pyopenssl
    #     python-crontab
    #     quart
    #     readerwriterlock
    #   ]);
    # });

  })
  [ "python310" "python311" ]
  final
  prev
