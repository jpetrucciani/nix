# This overlay acts as the last overlay, allowing me to add attributes after every other overlay in this repo
final: prev:
let
  inherit (final.lib) elem all id isDerivation;
  inherit (final.lib.lists) remove;
  inherit (final.lib.attrsets) filterAttrs;
  checked_packages = filterAttrs
    (_: pkg: all id [
      (isDerivation pkg)
      (elem final.system pkg.meta.platforms or [ final.system ])
      (!pkg.meta.broken or false)
      (!pkg.meta.skipBuild or false)
    ])
    prev.custom;

  _treefmt =
    let
      defaults = {
        binName = "jfmt";
        defaultPrograms = {
          # python
          black.enable = true;
          # ruff-check.enable = true;

          # nix
          nixpkgs-fmt.enable = true;
          deadnix = {
            enable = true;
            no-lambda-arg = true;
            no-underscore = true;
          };
          statix.enable = true;

          # js/md/yaml/etc.
          prettier = {
            enable = true;
            settings = {
              printWidth = 120;
              arrowParens = "always";
              singleQuote = true;
              tabWidth = 2;
              useTabs = false;
              semi = true;
              bracketSpacing = true;
              bracketSameLine = false;
              requirePragma = false;
              proseWrap = "preserve";
              trailingComma = "all";
            };
          };

          # bash
          shellcheck.enable = true;
          shfmt.enable = true;
        };
        extraPrograms = { };
        defaultGlobalExcludes = [
          ".dockerignore"
          ".env"
          ".envrc"
          ".prettierignore"
          ".terraformignore"
          "*.age"
          "*.conf"
          "*.csv"
          "*.ico"
          "*.ini"
          "*.jpeg"
          "*.jpg"
          "*.kube"
          "*.pem"
          "*.plist"
          "*.png"
          "*.repo"
          "*.rst"
          "*.service"
          "*.svg"
          "*.timer"
          "*.toml"
          "*.txt"
          "*.vsix"
          "*.xml"
          "*/.dockerignore"
          "*/.env"
          "*/.envrc"
          "*/.gitignore"
          "*/.prettierignore"
          "*/.terraformignore"
          "*/LICENSE"
          "flake.lock"
          "ignore"
          "LICENSE"
        ];
        extraGlobalExcludes = [ ];
        extraFormatter = { };
      };
      fn =
        { binName
        , defaultPrograms
        , extraPrograms
        , defaultGlobalExcludes
        , extraGlobalExcludes
        , extraFormatter
        }:
        let
          _t = prev.treefmt-nix.mkWrapper prev {
            projectRootFile = ".git/config";
            programs = final.lib.recursiveUpdate defaultPrograms extraPrograms;
            settings.global.excludes = defaultGlobalExcludes ++ extraGlobalExcludes;
            settings.formatter = { shellcheck.options = [ "-x" ]; } // extraFormatter;
          };
        in
        final.writeShellScriptBin binName ''${_t}/bin/treefmt "$@"'';
      result = fn defaults;
      treefmt = result // {
        override = newArgs: fn (defaults // newArgs);
        overrideWithDefaults = newArgs: fn (final.lib.recursiveUpdate defaults newArgs);
      };
    in
    treefmt // {
      __functor = _: treefmt.override;
    };

  llama-cpp-latest =
    let
      version = "b4712";
      hash = "sha256-H20djENYcgF5+q7GB/UpDh395h/nQ/kgEmqy7NC/aQA=";
    in
    prev.llama-cpp.overrideAttrs (_: {
      inherit version;
      src = final.fetchFromGitHub {
        inherit hash;
        tag = version;
        owner = "ggerganov";
        repo = "llama.cpp";
        leaveDotGit = true;
        postFetch = ''
          git -C "$out" rev-parse --short HEAD > $out/COMMIT
          find "$out" -name .git -print0 | xargs -0 rm -rf
        '';
      };
    });
in
{
  inherit llama-cpp-latest;
  foundry = import ./foundry.nix { pkgs = prev; };
  __j_custom = prev.buildEnv {
    name = "__j_custom";
    paths = (prev.lib.attrsets.attrValues checked_packages) ++ [ prev.hex prev.nix (prev.python311.withPackages prev.hax.basePythonPackages) ];
  };

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

  uv-helpers = {
    mkEnv = { name, workspaceRoot, envName ? "${name}-env", python ? final.python312, sourcePreference ? "wheel", pyprojectOverrides ? null }:
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
        _pyprojectOverrides = _final: _prev: {
          # Implement standard build fixups here.
          # Note that uv2nix is _not_ using Nixpkgs buildPythonPackage.
          # It's using https://pyproject-nix.github.io/pyproject.nix/build.html
        };
        pythonSet =
          # Use base package set from pyproject.nix builders
          (final.callPackage final.pyproject-nix.build.packages {
            inherit python;
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

  inherit _treefmt;
  jfmt = _treefmt;

  _nix = final.lix;

  llama-cpp-cuda = prev.llama-cpp.override { cudaSupport = true; };
  llama-cpp-cuda-latest = llama-cpp-latest.override { cudaSupport = true; };

  getpwuid_hack = final.stdenv.mkDerivation rec {
    name = "pwuid-override";
    version = "0.1.0";
    src = final.writeTextFile {
      name = "pwuid_override.c";
      text = ''
        #define _GNU_SOURCE
        #include <dlfcn.h>
        #include <pwd.h>
        #include <stdio.h>
        #include <stdlib.h>
        #include <string.h>
        #include <unistd.h>

        static struct passwd pwd;
        static char name_buf[1024];
        static char dir_buf[1024];
        static char shell_buf[1024];

        struct passwd *getpwuid(uid_t uid) {
            char *username = getenv("USER");
            if (!username) {
                return NULL;
            }

            strncpy(name_buf, username, sizeof(name_buf)-1);
            snprintf(dir_buf, sizeof(dir_buf), "/home/%s", username);
            strncpy(shell_buf, "/bin/bash", sizeof(shell_buf)-1);

            pwd.pw_name = name_buf;
            pwd.pw_passwd = "x";
            pwd.pw_uid = uid;
            pwd.pw_gid = uid;  // Using same as uid for simplicity
            pwd.pw_gecos = "";
            pwd.pw_dir = dir_buf;
            pwd.pw_shell = shell_buf;

            return &pwd;
        }
      '';
    };

    dontUnpack = true;

    buildPhase = ''
      $CC -shared -fPIC ${src} -o libpwuid_override.so -ldl
    '';

    installPhase = ''
      mkdir -p $out/lib
      cp libpwuid_override.so $out/lib/
    '';
  };

  openai-whisper-cpp-cuda = prev.openai-whisper-cpp.override { cudaSupport = true; };
}
