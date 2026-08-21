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

  _oxfmt = {
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
          oxfmt = {
            enable = true;
            settings = _oxfmt;
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
      version = "10430";
      hash = "sha256-jhMnyPKgHZfDAJUhjaZt38Hiflf9MnFb5xZutkJ/cTk=";
    in
    prev.llama-cpp.overrideAttrs (old: {
      inherit version;
      src = final.fetchFromGitHub {
        inherit hash;
        tag = "b${version}";
        owner = "ggml-org";
        repo = "llama.cpp";
        leaveDotGit = true;
        postFetch = ''
          git -C "$out" rev-parse --short HEAD > $out/COMMIT
          find "$out" -name .git -print0 | xargs -0 rm -rf
        '';
      };
      npmRoot = "tools/ui";
      npmDepsHash = "sha256-2Q7XhaLAArmviOLdQsNbYTfdyDE5pW9lR26cRHEVl9k=";
      # hack for mac dylib?
      cmakeFlags = if final.stdenv.hostPlatform.isDarwin then old.cmakeFlags ++ [ "-DLLAMA_BUILD_NUMBER=1" ] else old.cmakeFlags;
    });

  stable-diffusion-cpp-latest =
    let
      version = "master-585-44cca3d";
      hash = "sha256-ExriJzuVfU+ubLaj9sJK/yrW/3RWAjZ0RK4kgmsDY9g=";
    in
    prev.stable-diffusion-cpp.overrideAttrs (old: {
      inherit version;
      src = final.fetchFromGitHub {
        inherit hash;
        owner = "leejet";
        repo = "stable-diffusion.cpp";
        rev = version;
        fetchSubmodules = true;
      };
    });

  codex-latest =
    let
      version = "0.149.0";
      v8Version = "150.4.0";
      v8Features = [ "ptrcomp" "sandbox" ];
      v8ReleaseBase = "https://github.com/openai/codex/releases/download/rusty-v8-v${v8Version}";
      # Generate hashes with:
      # v8_version=$(sed -n 's/.*v8Version = "\([^"]*\)";.*/\1/p' mods/final.nix); \
      # for target in aarch64-apple-darwin aarch64-unknown-linux-gnu x86_64-unknown-linux-gnu; do \
      #   for artifact in "librusty_v8_ptrcomp_sandbox_release_${target}.a.gz" "src_binding_ptrcomp_sandbox_release_${target}.rs"; do \
      #     file=$(mktemp); curl -L --fail --silent --show-error -o "$file" \
      #       "https://github.com/openai/codex/releases/download/rusty-v8-v${v8_version}/${artifact}"; \
      #     printf '%s ' "$artifact"; nix hash file --type sha256 --sri "$file"; rm "$file"; \
      #   done; \
      # done
      v8ArchiveHashes = {
        aarch64-darwin = "sha256-AK27SHmISMd1UEQcaGc6XoUpuOG3PqvN7iMss5tA9KE=";
        aarch64-linux = "sha256-0VF+7UBUaFNwKbAF1f6ZfsdNXI01H5FrOm3yC30oEbo=";
        x86_64-linux = "sha256-o1x10fJuapg4haRbM0kKTr5U8FBQVosyuJz7QhswtYM=";
      };
      v8BindingHashes = {
        aarch64-darwin = "sha256-ylrfDPicmnCtRgrnNkiy/om3SqETs8t/dXtqArdYOU8=";
        aarch64-linux = "sha256-dyeCauR5vbZF6Acjn7EtH44uI956bPFvXuWSaQ0dhQY=";
        x86_64-linux = "sha256-dyeCauR5vbZF6Acjn7EtH44uI956bPFvXuWSaQ0dhQY=";
      };
      src = final.fetchFromGitHub {
        owner = "openai";
        repo = "codex";
        tag = "rust-v${version}";
        hash = "sha256-SMVTW/CcGz4xxyeFe3KUf3Ns6jp+2SRMTvtA2o2+y7Q=";
      };
      librustyV8 = final.fetchLibrustyV8 {
        version = v8Version;
        hashes = v8ArchiveHashes;
        features = v8Features;
        releaseBase = v8ReleaseBase;
      };
      rustyV8Binding = final.fetchRustyV8Binding {
        version = v8Version;
        hashes = v8BindingHashes;
        features = v8Features;
        releaseBase = v8ReleaseBase;
      };
    in
    prev.codex.overrideAttrs (old: {
      inherit version src;
      postPatch = ''
        substituteInPlace Cargo.toml \
          --replace-fail 'lto = "thin"' "" \
          --replace-fail 'codegen-units = 4' ""
      '';
      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit src;
        sourceRoot = "${src.name}/codex-rs";
        hash = "sha256-K58PL588Hhk75FyXgU6b8IEAco8FIz8oGd1S0WgOjyQ=";
      };
      env = builtins.removeAttrs (old.env or { }) [ "LK_CUSTOM_WEBRTC" ] // {
        RUSTY_V8_ARCHIVE = librustyV8;
        RUSTY_V8_SRC_BINDING_PATH = rustyV8Binding;
      };
    });
in
{
  inherit llama-cpp-latest codex-latest stable-diffusion-cpp-latest;
  foundry = import ./foundry.nix { pkgs = final; };
  __j_custom = final.buildEnv {
    name = "__j_custom";
    paths = (final.lib.attrsets.attrValues checked_packages) ++ [ final.hex final.nix (final.python314.withPackages final.hax.basePythonPackages) ];
    ignoreCollisions = true;
  };

  inherit _treefmt _oxfmt;
  jfmt = _treefmt;

  _nix = final.nixVersions.nix_2_34;

  llama-cpp-cuda = prev.llama-cpp.override { cudaSupport = true; };
  llama-cpp-cuda-latest = llama-cpp-latest.override { cudaSupport = true; };
  stable-diffusion-cpp-cuda-latest = stable-diffusion-cpp-latest.override { cudaSupport = true; };
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

  inherit (final.python314Packages) ty;

  # allow 3proxy on darwin?
  _3proxy = prev._3proxy.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ (if final.stdenv.hostPlatform.isDarwin then [ final.pam ] else [ ]);
    makeFlags =
      if final.stdenv.hostPlatform.isDarwin then [
        "-f Makefile.FreeBSD"
        "INSTALL=install"
        "DESTDIR=${placeholder "out"}"
        "all"
        # "CC:=$(CC)"
      ] else old.makeFlags;
    installPhase =
      if final.stdenv.hostPlatform.isDarwin then ''
        mkdir -p $out
        mv ./bin $out/.
      '' else (old.installPhase or "");
    meta = old.meta // {
      platforms = final.lib.platforms.all;
    };
  });

  time =
    if final.stdenv.hostPlatform.isDarwin then
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

  proxysql-2 = (import
    (fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/8243a08149705f52dde1b310e07a679c32422695.tar.gz";
      sha256 = "00gjkaayapgi11k0dgngv51fcbkbahk659vlf4ffgi5qlvc7ni5a";
    })
    { inherit (final.stdenv.hostPlatform) system; }).proxysql;

  mountpoint-s3-latest =
    let
      version = "1.22.3";
      src = final.fetchFromGitHub {
        owner = "awslabs";
        repo = "mountpoint-s3";
        tag = "v${version}";
        hash = "sha256-22tx8ozXkzBNAflDPc7cdfUh9TWD6aB/Fe/z/dPZ694=";
        fetchSubmodules = true;
      };
    in
    prev.mountpoint-s3.overrideAttrs (old: {
      inherit version src;
      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit src;
        name = "${old.pname}-${version}";
        hash = "sha256-SSSXqgJ3OERCVw81iXqXRRpVXgdwhlefHhI/qvQyl4g=";
      };
      checkFlags = (old.checkFlags or [ ]) ++ [
        "--skip=mountpoint-s3-client/src/lib.rs - (line 31)"
        "--skip=test_lookup_throttled_mock::both_list_and_head"
        "--skip=test_read_unhandled_error_mock"
      ];
    });
}
