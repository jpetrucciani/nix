{ pkgs
, treefmtLib ? pkgs.treefmt-nix
, writeShellScriptBin ? pkgs.writeShellScriptBin
}:
let
  inherit (pkgs.lib) recursiveUpdate;
  oxfmt = {
    printWidth = 120;
    arrowParens = "always";
    singleQuote = true;
    tabWidth = 2;
    useTabs = false;
    semi = true;
    bracketSpacing = true;
    bracketSameLine = false;
    proseWrap = "preserve";
    trailingComma = "all";
    ignorePatterns = [ "flake.lock" ];
  };

  jfmt =
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
          oxfmt = {
            enable = true;
            settings = oxfmt;
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
        , extraTreefmt ? { }
        , projectRootFile ? ".git/config"
        }:
        let
          _t = treefmtLib.mkWrapper pkgs (recursiveUpdate
            {
              inherit projectRootFile;
              programs = recursiveUpdate defaultPrograms extraPrograms;
              settings.global.excludes = defaultGlobalExcludes ++ extraGlobalExcludes;
              settings.formatter = { shellcheck.options = [ "-x" ]; } // extraFormatter;
            }
            extraTreefmt);
        in
        writeShellScriptBin binName ''${_t}/bin/treefmt "$@"'';
      result = fn defaults;
      treefmt = result // {
        override = newArgs: fn (defaults // newArgs);
        overrideWithDefaults = newArgs: fn (recursiveUpdate defaults newArgs);
      };
    in
    treefmt // {
      __functor = _: treefmt.override;
    };
in
{ inherit jfmt oxfmt; }
