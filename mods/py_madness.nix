# This overlay is where I create wrappers around other tools to simplify using some of the attempts to simplify python tooling via nix
final: prev:
let
  inherit (final.lib.lists) remove;

  poetry-helpers = rec {
    add_propagated = pkg: propagated: pkg.overridePythonAttrs (old: {
      propagatedBuildInputs = (old.propagatedBuildInputs or [ ]) ++ propagated;
    });
    remove_propagated = pkg: _remove: pkg.overridePythonAttrs (old: {
      propagatedBuildInputs = remove _remove (old.propagatedBuildInputs or [ ]);
    });
    no_wheel = pkg: pkg.override { preferWheel = false; };
    no_check = pkg: pkg.overridePythonAttrs (_: { doCheck = false; });
    mkEnv =
      { projectDir
      , extraOverrides ? [ ]
      , extraPreOverrides ? [ ]
      , extraPostOverrides ? extraOverrides
      , extraBuildInputs ? [ ]
      , editablePackageSources ? { }
      , extraMkPoetryEnv ? { }
      , python ? final.python312
      , ignoreCollisions ? true
      , preferWheels ? true
      }:
      let
        p2nix = final.poetry2nix;
        extraFixes = final: prev:
          let
            add_setuptools = pkg: add_propagated pkg [ final.setuptools ];
          in
          # some default fixes for things i've seen
          {
            # import from nixpkgs
            inherit (python.pkgs) pymupdf markupsafe;

            # do not pull wheels!
            bcrypt = no_wheel prev.bcrypt;
            contourpy = no_wheel prev.contourpy;
            jsonschema = no_wheel prev.jsonschema;
            jsonschema-specifications = no_wheel prev.jsonschema-specifications;
            jupyterlab-pygments = no_wheel prev.jupyterlab-pygments;
            markdown-it-py = no_wheel prev.markdown-it-py;
            msgpack = no_wheel prev.msgpack;
            nbconvert = no_wheel prev.nbconvert;
            numba = no_wheel prev.numba;
            orjson = no_wheel prev.orjson;
            pytesseract = no_wheel prev.pytesseract;
            referencing = no_wheel prev.referencing;
            reportlab = no_wheel prev.reportlab;
            rpds-py = no_wheel prev.rpds-py;
            scikit-learn = no_wheel prev.scikit-learn;
            scipy = no_wheel prev.scipy;
            watchfiles = no_wheel prev.watchfiles;

            # requires setuptools
            py-lets-be-rational = add_setuptools prev.py-lets-be-rational;
            pypika = add_setuptools prev.pypika;
            swifter = add_setuptools prev.swifter;
            wikipedia = add_setuptools prev.wikipedia;
            xalglib = add_setuptools prev.xalglib;

            # other required propagations
            jupyterlab-miami-nights = add_propagated prev.jupyterlab-miami-nights [ prev.jupyter-packaging ];
          };
      in
      ((p2nix.mkPoetryEnv
        {
          inherit editablePackageSources python projectDir preferWheels;
          overrides = extraPreOverrides ++ (p2nix.overrides.withDefaults extraFixes) ++ extraPostOverrides;
        } // extraMkPoetryEnv).override
        (args: {
          inherit ignoreCollisions;
        })).overrideAttrs
        (old: {
          buildInputs = with final; [
            libcxx
          ] ++ extraBuildInputs;
        });
  };

  uv-nix = {
    mkEnv = { name, workspaceRoot, envName ? "${name}-env", python ? final.python312, sourcePreference ? "wheel", pyprojectOverrides ? null, darwinSdkVersion ? "15.1" }:
      let
        workspace = final.uv2nix.lib.workspace.loadWorkspace { inherit workspaceRoot; };
        overlay = workspace.mkPyprojectOverlay {
          # Prefer prebuilt binary wheels as a package source.
          # Sdists are less likely to "just work" because of the metadata missing from uv.lock.
          # Binary wheels are more likely to, but may still require overrides for library dependencies.
          inherit sourcePreference; # or sourcePreference = "sdist";
          # Optionally customise PEP 508 environment
          # environ = {
          #   platform_release = "5.10.65";
          # };
        };
        _pyprojectOverrides = _final: _prev:
          let
            add_buildinputs = build_inputs: pkg: pkg.overrideAttrs (old: {
              buildInputs = (old.buildInputs or [ ]) ++ build_inputs;
            });
            add_setuptools = add_buildinputs [ _final.setuptools ];
          in
          {
            # Implement standard build fixups here.
            # Note that uv2nix is _not_ using Nixpkgs buildPythonPackage.
            # It's using https://pyproject-nix.github.io/pyproject.nix/build.html
            docx2txt = add_setuptools _prev.docx2txt;
            pypika = add_setuptools _prev.pypika;
          };
        pythonSet =
          # Use base package set from pyproject.nix builders
          (final.callPackage final.pyproject-nix.build.packages {
            inherit python;
            stdenv = final.stdenv.override {
              targetPlatform = final.stdenv.targetPlatform // (if final.stdenv.isDarwin then {
                # Sets MacOS SDK version to 15.1 which implies Darwin version 24.
                # See https://en.wikipedia.org/wiki/MacOS_version_history#Releases for more background on version numbers.
                inherit darwinSdkVersion;
              } else { });
            };
          }).overrideScope
            (
              final.lib.composeManyExtensions [
                final.pyproject-build-systems.overlays.default
                overlay
                _pyprojectOverrides
                pyprojectOverrides
              ]
            );

        virtualenv = pythonSet.mkVirtualEnv envName workspace.deps.all;
      in
      virtualenv // {
        uvEnvVars = {
          UV_NO_SYNC = "1";
          UV_PYTHON = "${virtualenv}/bin/python";
          UV_PYTHON_DOWNLOADS = "never";
        };
      };
  };
in
{
  inherit poetry-helpers uv-nix;
  poetry-nix = poetry-helpers; # i'd like to rename this permanently?
}
