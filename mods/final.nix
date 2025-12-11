# This overlay acts as the last overlay, allowing me to add attributes after every other overlay in this repo
final: prev:
let
  inherit (final.lib) elem all id isDerivation recursiveUpdate;
  inherit (final.lib.attrsets) filterAttrs;
  checked_packages = filterAttrs
    (_: pkg: all id [
      (isDerivation pkg)
      (elem final.stdenv.hostPlatform.system pkg.meta.platforms or [ final.stdenv.hostPlatform.system ])
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
      version = "7186"; # qwen3-next support
      hash = "sha256-3iJF/wDS6GnOWCio2inC4GFa8yWWTTlyxlU5vU2Pg9o=";
    in
    prev.llama-cpp.overrideAttrs (old: {
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
      # hack for mac dylib?
      cmakeFlags =
        if final.stdenv.isDarwin then old.cmakeFlags ++ [
          "-DLLAMA_BUILD_NUMBER=1"
        ] else old.cmakeFlags;
    });
in
{
  inherit llama-cpp-latest;
  foundry = import ./foundry.nix { pkgs = final; };
  __j_custom = final.buildEnv {
    name = "__j_custom";
    paths = (final.lib.attrsets.attrValues checked_packages) ++ [ final.hex final.nix (final.python313.withPackages final.hax.basePythonPackages) ];
    ignoreCollisions = true;
  };

  inherit _treefmt;
  jfmt = _treefmt;

  _nix = final.nixVersions.nix_2_32;

  llama-cpp-cuda = prev.llama-cpp.override { cudaSupport = true; };
  llama-cpp-cuda-latest = llama-cpp-latest.override { cudaSupport = true; };
  koboldcpp-cuda = prev.koboldcpp.override { config.cudaSupport = true; };

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
        rev = "349b035a5027f23d88eeb3bc41085d7ee29f18ed";
        sha256 = "sha256-QVey3iP3UEoiFVXgypyjTvCrsIlA4ecx6Acaz5C8/PQ=";
      };
    in
    prev.colmena.overrideAttrs (_: {
      inherit src version;
      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit pname version src;
        hash = "sha256-v5vv66x+QiDhSa3iJ3Kf7PC8ZmK1GG8QdVD2a1L0r6M=";
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

  awscli2 = prev.awscli2.overridePythonAttrs (_: { doCheck = false; });

  time =
    if final.stdenv.isDarwin then
      prev.time.overrideAttrs
        (_: {
          postPatch = ''
            sed -E -i 's#__sighandler_t#sighandler_t#g' src/time.c
          '';
        }) else prev.time;

  htop-noaffinity = prev.htop.overrideAttrs (old: {
    configureFlags = (final.lib.lists.remove [ "--enable-affinity" ] (old.configureFlags or [ ])) ++ [ "--disable-affinity" ];
  });

  bomber-go =
    let
      version = "0.5.1";
      hash = "sha256-D3xs8lVhrRKVVQYzHN7CQNw5NTC+AxgsWvJxnV0lwGY=";
      vendorHash = "sha256-mhGnuNuvMvX4WsqnS7QkWcrPfWEyaQsSKDUOpg9YrO8=";
      skipTests =
        let
          tests = [
            "TestEnrich"
            "TestScanner_enrichVulnerabilities"
          ];
        in
        final.lib.concatStringsSep "|" tests;
    in
    prev.bomber-go.overrideAttrs (_: {
      passthru.latest = prev.bomber-go.overrideAttrs (old: {
        inherit version vendorHash;
        inherit (old) passthru;
        src = final.fetchFromGitHub {
          inherit hash;
          owner = "devops-kung-fu";
          repo = "bomber";
          tag = "v${version}";
        };
        checkPhase = ''
          runHook preCheck
          go test -skip='${skipTests}' ./...
          runHook postCheck
        '';
      });
    });
}
