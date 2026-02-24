final: prev:
let
  inherit (final) pythonOlder;
  inherit (final.stdenv) isDarwin;
in
rec {
  tkinter =
    if pythonOlder "3.12" then
      let
        inherit (final) python py;
      in
      final.buildPythonPackage
        {
          pname = "tkinter";
          inherit (python) version;
          src = py;
          format = "other";
        } else prev.tkinter;

  roman-numerals-py = final.buildPythonPackage rec {
    pname = "roman-numerals-py";
    version = "3.1.0";
    pyproject = true;

    src = final.pkgs.fetchFromGitHub {
      owner = "AA-Turner";
      repo = "roman-numerals";
      tag = "v${version}";
      hash = "sha256-YLF09jYwXq48iMvmqbj/cocYJPp7RsCXzbN0DV9gpis=";
    };

    postPatch = ''
      ls -lah
      cp LICENCE.rst python/

      cd python
    '';

    build-system = with final; [ flit-core ];

    nativeCheckInputs = with final; [ pytestCheckHook ];

    pythonImportsCheck = [ "roman_numerals" ];

    meta = with final; {
      description = "Manipulate roman numerals";
      mainProgram = "roman-numerals-py";
      platforms = lib.platforms.all;
    };
  };

  sphinx =
    if pythonOlder "3.12" then
      let
        docutils = final.buildPythonPackage rec {
          pname = "docutils";
          version = "0.21.2";
          pyproject = true;

          src = final.pkgs.fetchurl {
            url = "mirror://sourceforge/docutils/docutils-${version}.tar.gz";
            hash = "sha256-OmsYcy7fGC2qPNEndbuzOM9WkUaPke7rEJ3v9uv6mG8=";
          };

          build-system = with final; [ flit-core ];

          # infinite recursion via sphinx and pillow
          doCheck = false;

          nativeCheckInputs = with final; [ pillow ];

          # Create symlinks lacking a ".py" suffix, many programs depend on these names
          postFixup = ''
            for f in $out/bin/*.py; do
              ln -s $(basename $f) $out/bin/$(basename $f .py)
            done
          '';

          pythonImportsCheck = [ "docutils" ];
        };
      in
      final.buildPythonPackage
        rec {
          pname = "sphinx";
          version = "8.2.3";
          pyproject = true;

          disabled = pythonOlder "3.11";

          src = final.pkgs.fetchFromGitHub {
            owner = "sphinx-doc";
            repo = "sphinx";
            tag = "v${version}";
            postFetch = ''
              # Change ä to æ in file names, since ä can be encoded multiple ways on different
              # filesystems, leading to different hashes on different platforms.
              cd "$out";
              mv tests/roots/test-images/{testimäge,testimæge}.png
              sed -i 's/testimäge/testimæge/g' tests/{test_build*.py,roots/test-images/index.rst}
            '';
            hash = "sha256-FoyCpDGDKNN2GMhE7gDpJLmWRWhbMCYlcVEaBTfXSEw=";
          };

          build-system = with final;[ flit-core ];

          dependencies = with final;[
            alabaster
            babel
            docutils
            imagesize
            jinja2
            packaging
            pygments
            requests
            roman-numerals-py
            snowballstemmer
            sphinxcontrib-applehelp
            sphinxcontrib-devhelp
            sphinxcontrib-htmlhelp
            sphinxcontrib-jsmath
            sphinxcontrib-qthelp
            sphinxcontrib-serializinghtml
            # extra[docs]
            sphinxcontrib-websupport
          ]
          ++ lib.optionals (pythonOlder "3.11") [ tomli ]
          ++ lib.optionals (pythonOlder "3.10") [ importlib-metadata ];

          __darwinAllowLocalNetworking = true;

          nativeCheckInputs = with final; [
            defusedxml
            filelock
            html5lib
            pytestCheckHook
            pytest-xdist
            typing-extensions
          ];

          preCheck = ''
            export HOME=$TMPDIR
          '';

          disabledTests = [
            # requires network access
            "test_latex_images"
            # racy
            "test_defaults"
            "test_check_link_response_only"
            "test_anchors_ignored_for_url"
            "test_autodoc_default_options"
            "test_too_many_requests_retry_after_int_delay"
            # racy with pytest-xdist
            "test_domain_cpp_build_semicolon"
            "test_class_alias"
            "test_class_alias_having_doccomment"
            "test_class_alias_for_imported_object_having_doccomment"
            "test_decorators"
            "test_xml_warnings"
            # racy with too many threads
            # https://github.com/NixOS/nixpkgs/issues/353176
            "test_document_toc_only"
            # Assertion error
            "test_gettext_literalblock_additional"
            # requires cython_0, but fails miserably on 3.11
            "test_cython"
            # Could not fetch remote image: http://localhost:7777/sphinx.png
            "test_copy_images"
            # ModuleNotFoundError: No module named 'fish_licence.halibut'
            "test_import_native_module_stubs"
            # Racy tex file creation
            "test_literalinclude_namedlink_latex"
            "test_literalinclude_caption_latex"
            # Racy local networking
            "test_load_mappings_cache"
            "test_load_mappings_cache_update"
            "test_load_mappings_cache_revert_update"
          ];
        } else prev.sphinx;

  sqlalchemy_1 =
    let
      version = "1.4.48";
    in
    prev.sqlalchemy.overridePythonAttrs (_: {
      inherit version;
      src = final.fetchPypi {
        inherit version;
        pname = "SQLAlchemy";
        hash = "sha256-tHvChwltmJoIOM6W99jpZpFKJNqHftQadTHUS1XNuN8=";
      };
      passthru.replaceSqlalchemy = old: {
        propagatedBuildInputs = final.lib.remove prev.sqlalchemy old.propagatedBuildInputs or [ ] ++ [ sqlalchemy_1 ];
      };
      disabledTestPaths = [ ];
      disabledTests = final.lib.optionals final.stdenv.isDarwin [
        "MemUsageWBackendTest"
        "MemUsageTest"
      ];
    });

  python-binance = prev.python-binance.overridePythonAttrs (old: {
    postPatch = ''
      sed -i -E 's#raise.*#version = "${old.version}"#g' ./setup.py
    '';
    propagatedBuildInputs = old.propagatedBuildInputs ++ [ final.pycryptodome ];
  });

  prometheus-fastapi-instrumentator =
    if isDarwin then
      prev.prometheus-fastapi-instrumentator.overridePythonAttrs
        (_: {
          doCheck = false;
          meta.platforms = final.lib.platforms.all;
        }) else prev.prometheus-fastapi-instrumentator;

  emoji_1 = final.buildPythonPackage rec {
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
      final.pytestCheckHook
    ];

    disabledTests = [
      "test_emojize_name_only"
    ];

    pythonImportsCheck = [
      "emoji"
    ];

    meta = with final.pkgs.lib; {
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
