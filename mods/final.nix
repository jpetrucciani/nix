# This overlay acts as the last overlay, allowing me to add attributes after every other overlay in this repo
final: prev:
let
  inherit (final.lib) elem all id isDerivation recursiveUpdate;
  inherit (final.lib.attrsets) filterAttrs;
  checked_packages = filterAttrs
    (_: pkg: all id [
      (isDerivation pkg)
      (elem final.system pkg.meta.platforms or [ final.system ])
      (!pkg.meta.broken or false)
      (!pkg.meta.skipBuild or false)
    ])
    final.custom;

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
        , extraTreefmt ? { }
        , projectRootFile ? ".git/config"
        }:
        let
          _t = prev.treefmt-nix.mkWrapper prev (recursiveUpdate
            {
              inherit projectRootFile;
              programs = recursiveUpdate defaultPrograms extraPrograms;
              settings.global.excludes = defaultGlobalExcludes ++ extraGlobalExcludes;
              settings.formatter = { shellcheck.options = [ "-x" ]; } // extraFormatter;
            }
            extraTreefmt);
        in
        final.writeShellScriptBin binName ''${_t}/bin/treefmt "$@"'';
      result = fn defaults;
      treefmt = result // {
        override = newArgs: fn (defaults // newArgs);
        overrideWithDefaults = newArgs: fn (recursiveUpdate defaults newArgs);
      };
    in
    treefmt // {
      __functor = _: treefmt.override;
    };

  llama-cpp-latest =
    let
      version = "6497";
      hash = "sha256-deOTNDP7sKESqwsXQgMzLnX1s3WZdkxDOqHGyB5ckKU=";
    in
    prev.llama-cpp.overrideAttrs (_: {
      inherit version;
      src = final.fetchFromGitHub {
        inherit hash;
        tag = "b${version}";
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
    paths = (prev.lib.attrsets.attrValues checked_packages) ++ [ prev.hex prev.nix (prev.python313.withPackages prev.hax.basePythonPackages) ];
  };

  inherit _treefmt;
  jfmt = _treefmt;

  _nix = final.nixVersions.nix_2_30;

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

  colmena-latest =
    let
      pname = "colmena";
      version = "0.5.0";
      src = final.fetchFromGitHub {
        owner = "zhaofengli";
        repo = pname;
        # rev = "v${version}";
        rev = "2370d4336eda2a9ef29fce10fa7076ae011983ab";
        sha256 = "sha256-hPSLvw6AZQYrZyGI6Uq4XgST7benF/0zcCpugn/P0yM=";
      };
    in
    prev.colmena.overrideAttrs (_: {
      inherit src version;
      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit pname version src;
        hash = "sha256-fuo2qDORVfUfmLWux9GYh2O0GbrQSaBLOFTE4dReOGQ=";
      };
      patches = [ ];
      postInstall = final.lib.optionalString (final.stdenv.buildPlatform.canExecute final.stdenv.hostPlatform) ''
        installShellCompletion --cmd colmena \
          --bash <($out/bin/colmena gen-completions bash) \
          --zsh <($out/bin/colmena gen-completions zsh) \
          --fish <($out/bin/colmena gen-completions fish)

        wrapProgram $out/bin/colmena \
          --prefix PATH ":" "${final.lib.makeBinPath [ final._nix ]}"
      '';
    });

  inherit (final.python313Packages) ty;

  # allow 3proxy on darwin?
  _3proxy = prev._3proxy.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ (if final.stdenv.isDarwin then [ final.pam ] else [ ]);
    makeFlags =
      if final.stdenv.isDarwin then [
        "-f Makefile.FreeBSD"
        "INSTALL=install"
        "DESTDIR=${placeholder "out"}"
        "all"
        # "CC:=$(CC)"
      ] else old.makeFlags;
    installPhase =
      if final.stdenv.isDarwin then ''
        mkdir -p $out
        mv ./bin $out/.
      '' else (old.installPhase or "");
    meta = old.meta // {
      platforms = final.lib.platforms.all;
    };
  });
}
