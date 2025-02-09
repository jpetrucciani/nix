final: prev:
let
  inherit (final) pythonOlder fetchPypi buildPythonPackage;
  inherit (final.stdenv) isDarwin;
  inherit (final.pkgs) fetchFromGitHub lib;
in
rec {
  sqlalchemy_1 =
    let
      version = "1.4.48";
    in
    prev.sqlalchemy.overridePythonAttrs (_: {
      inherit version;
      src = prev.fetchPypi {
        inherit version;
        pname = "SQLAlchemy";
        hash = "sha256-tHvChwltmJoIOM6W99jpZpFKJNqHftQadTHUS1XNuN8=";
      };
      passthru.replaceSqlalchemy = old: {
        propagatedBuildInputs = prev.lib.remove prev.sqlalchemy old.propagatedBuildInputs or [ ] ++ [ sqlalchemy_1 ];
      };
      disabledTestPaths = [ ];
      disabledTests = prev.lib.optionals prev.stdenv.isDarwin [
        "MemUsageWBackendTest"
        "MemUsageTest"
      ];
    });

  python-binance = prev.python-binance.overridePythonAttrs (old: {
    postPatch = ''
      sed -i -E 's#raise.*#version = "${old.version}"#g' ./setup.py
    '';
    propagatedBuildInputs = old.propagatedBuildInputs ++ [ prev.pycryptodome ];
  });

  prometheus-fastapi-instrumentator =
    if isDarwin then
      prev.prometheus-fastapi-instrumentator.overridePythonAttrs
        (_: {
          doCheck = false;
          meta.platforms = prev.lib.platforms.all;
        }) else prev.prometheus-fastapi-instrumentator;

  emoji_1 = prev.buildPythonPackage rec {
    pname = "emoji";
    version = "1.7.0";
    format = "setuptools";

    disabled = pythonOlder "3.7";

    src = prev.pkgs.fetchFromGitHub {
      owner = "carpedm20";
      repo = pname;
      rev = "refs/tags/v${version}";
      hash = "sha256-vKQ51RP7uy57vP3dOnHZRSp/Wz+YDzeLUR8JnIELE/I=";
    };

    nativeCheckInputs = [
      prev.pytestCheckHook
    ];

    disabledTests = [
      "test_emojize_name_only"
    ];

    pythonImportsCheck = [
      "emoji"
    ];

    meta = with prev.pkgs.lib; {
      description = "Emoji for Python";
      homepage = "https://github.com/carpedm20/emoji/";
      changelog = "https://github.com/carpedm20/emoji/blob/v${version}/CHANGES.md";
      license = licenses.bsd3;
      maintainers = with maintainers; [ joachifm ];
    };
  };

  pypdfium2 = prev.pypdfium2.overridePythonAttrs (_:
    let
      headers = final.pkgs.fetchgit {
        url = "https://pdfium.googlesource.com/pdfium";
        # The latest revision on the chromium/${pdfiumVersion} branch
        rev = "f6da7d235728aeaff6586d2190badfb4290a9979";
        hash = "sha256-Es/IDQPLQGOFhoAY93zduc+eKGpA7qMnLw7TjZpWHvc=";
      };
      inherit (final.pkgs) pdfium-binaries;
      pdfiumVersion = "${pdfium-binaries.version}";
    in
    {
      preBuild =
        let
          pdfiumLib = final.pkgs.lib.makeLibraryPath [ pdfium-binaries ];
          inputVersionFile = (final.pkgs.formats.json { }).generate "version.json" {
            version = final.pkgs.lib.strings.toInt pdfiumVersion;
            source = "generated";
            flags = [ ];
            run_lds = [ pdfiumLib ];
            guard_symbols = false;
          };
          bindingsDir = "data/bindings";
          headersDir = "${bindingsDir}/headers";
          versionFile = "${bindingsDir}/version.json";
        in
        ''
          # Preseed the headers and version file
          mkdir -p ${bindingsDir}
          cp -r ${headers}/public ${headersDir}
          install -m 644 ${inputVersionFile} ${versionFile}

          # Make generated bindings consider pdfium derivation path when loading dynamic libraries
          substituteInPlace setupsrc/pypdfium2_setup/emplace.py \
            --replace-fail 'build_pdfium_bindings(pdfium_ver, flags=flags, guard_symbols=True, run_lds=[])' \
                           'build_pdfium_bindings(pdfium_ver, flags=flags, guard_symbols=True, run_lds=["${pdfiumLib}"])'

          # Short circuit the version pull from the internet
          substituteInPlace setupsrc/pypdfium2_setup/packaging_base.py \
            --replace-fail 'PdfiumVer.to_full(build)._asdict()' \
                           '{"major": 133, "minor": 0, "build": ${pdfiumVersion}, "patch": 1}'
        '';
    });

  certbot-dns-cloudflare-latest = buildPythonPackage
    rec {
      pname = "certbot-dns-cloudflare";
      version = "3.1.0";
      pyproject = true;

      src = fetchPypi {
        pname = "certbot_dns_cloudflare";
        inherit version;
        hash = "sha256-oktsloLV/CwzYLJ+y19NKfMYjOgAm3miTBnkfK6jzgM=";
      };

      build-system = with final; [
        setuptools
        wheel
      ];

      dependencies = with final; [
        acme
        certbot
        (buildPythonPackage rec {
          pname = "cloudflare";
          version = "2.19.4";
          pyproject = true;

          src = fetchPypi {
            inherit pname version;
            hash = "sha256-O2AAoBojfCO8z99tICVupREex0qCaunnT58OW7WyOD8=";
          };

          build-system = [
            setuptools
            wheel
          ];

          dependencies = [
            anyio
            distro
            httpx
            jsonlines
            pydantic
            pyyaml
            requests
            sniffio
            typing-extensions
          ];

          pythonImportsCheck = [
            "CloudFlare"
          ];

          meta = {
            description = "The official Python library for the cloudflare API";
            homepage = "https://pypi.org/project/cloudflare/2.19.4/";
            license = lib.licenses.mit;
            maintainers = with lib.maintainers; [ jpetrucciani ];
          };
        })
      ];

      optional-dependencies = with final; {
        docs = [
          sphinx
          sphinx-rtd-theme
        ];
        test = [
          pytest
        ];
      };

      pythonImportsCheck = [
        "certbot_dns_cloudflare"
      ];

      meta = {
        description = "Cloudflare DNS Authenticator plugin for Certbot";
        homepage = "https://pypi.org/project/certbot-dns-cloudflare/#history";
        license = lib.licenses.asl20;
        maintainers = with lib.maintainers; [ jpetrucciani ];
      };
    };

  anybadge = let version = "1.16.0"; in prev.anybadge.overridePythonAttrs (_: {
    postPatch = ''
      substituteInPlace ./setup.py \
        --replace 'version=get_version()' 'version="${version}"'

      substituteInPlace ./anybadge/__init__.py \
        --replace '"0.0.0"' '"${version}"'
    '';
    nativeCheckInputs = with final; [ sh ];
  });
}
