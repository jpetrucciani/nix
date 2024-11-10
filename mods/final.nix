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
      };
      fn =
        { binName
        , defaultPrograms
        , extraPrograms
        , defaultGlobalExcludes
        , extraGlobalExcludes
        }:
        let
          _t = prev.treefmt-nix.mkWrapper prev {
            projectRootFile = ".git/config";
            programs = final.lib.recursiveUpdate defaultPrograms extraPrograms;
            settings.global.excludes = defaultGlobalExcludes ++ extraGlobalExcludes;
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
in
{
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
            jupyterlab-pygments = no_wheel prev.jupyterlab-pygments;
            nbconvert = no_wheel prev.nbconvert;
            numba = no_wheel prev.numba;
            orjson = no_wheel prev.orjson;
            pytesseract = no_wheel prev.pytesseract;
            referencing = no_wheel prev.referencing;
            jsonschema-specifications = no_wheel prev.jsonschema-specifications;
            jsonschema = no_wheel prev.jsonschema;
            reportlab = no_wheel prev.reportlab;
            rpds-py = no_wheel prev.rpds-py;
            scipy = no_wheel prev.scipy;
            scikit-learn = no_wheel prev.scikit-learn;
            watchfiles = no_wheel prev.watchfiles;

            # requires setuptools
            py-lets-be-rational = add_setuptools prev.py-lets-be-rational;
            pypika = add_setuptools prev.pypika.overridePythonAttrs;
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

  inherit _treefmt;
  jfmt = _treefmt;

  _nix = final.lix;
}
