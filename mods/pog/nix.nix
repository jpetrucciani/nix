# This module configures some helper tools for creating new nix environments!
final: prev:
let
  inherit (final) _ pog lib;
  gitignore = import ./ignore.nix;
in
rec {
  nixup =
    let
      version = "0.0.11";
      _flags = {
        with_bun = "include bun with dependencies";
        with_crystal = "include crystal with dependencies";
        with_db_pg = "include postgres db and helper scripts";
        with_db_redis = "include redis db and helper scripts";
        with_dotnet = "include dotnet and the required libs";
        with_elixir = "include elixir with dependencies";
        with_golang = "include golang";
        with_java = "include a jvm and some basics";
        with_nim = "include a nim with dependencies";
        with_node = "include node";
        with_ocaml = "include an ocaml environment";
        with_php = "include a php with packages";
        with_poetry = "include python using poetry2nix";
        with_pulumi = "include pulumi";
        with_python = "include a python with packages";
        with_ruby = "include ruby";
        with_rust = "include rust";
        with_terraform = "include terraform";
        with_uv = "include python using uv2nix";
        with_vlang = "include a vlang with dependencies";
        with_nvidia = "include some ld hacks to get nvidia drivers working (only useful on nixos/wsl)";
      };
      flags = lib.mapAttrsToList (k: v: { name = k; description = v; short = ""; bool = true; }) _flags;
      jaq = lib.getExe final.jaq;
    in
    pog {
      inherit version;
      name = "nixup";
      description = "a quick tool to create/update a base default.nix environment! will also attempt to make you a baseline gitignore";
      flags = [
        { name = "srcpath"; description = "the fs path to import pkgs from if passed. if not passed in, will pin to the latest version of jpetrucciani/nix"; }
        { name = "update"; bool = true; description = "update the pin to jpetrucciani in the given file (argument 1) [default: ./default.nix]"; }
        { name = "repo"; description = "GitHub repo to pin (format: owner/repo)"; default = "jpetrucciani/nix"; }
        { name = "branch"; description = "Branch to pin to"; default = "main"; }
      ] ++ flags;
      shortDefaultFlags = false;
      script = h:
        ''
          directory="$(pwd | ${_.sed} 's#.*/##')"
          repo_owner=$(echo "$repo" | cut -d'/' -f1)
          repo_name=$(echo "$repo" | cut -d'/' -f2)
          remote=$(${final.nix_hash}/bin/nix_hash --repo "$repo" --branch "$branch" 2>/dev/null);
          rev=$(echo "$remote" | ${jaq} -r '.rev')
          sha=$(echo "$remote" | ${jaq} -r '.sha256')
          toplevel=""
          _env="pkgs.buildEnv {${"\n"} inherit name paths; buildInputs = paths; };"
          extra_env=""
          extra_env_overrides=""
          pkgs_import_args="{}"
          rust_overlay_arg=""
          gitignore="${gitignore.nix}"
          crystal=""
          if [ "$with_crystal" = "1" ]; then
            crystal="crystal = [crystal${"\n"}shards];"
            gitignore="$gitignore${"\n"}# crystal${"\n"}${gitignore.crystal}"
          fi
          pg=""
          if [ "$with_db_pg" = "1" ]; then
            pg="pg = __pg { postgres = pg; };${"\n"}pg_bootstrap = __pg_bootstrap { inherit name; postgres = pg; };${"\n"}pg_shell = __pg_shell { inherit name; postgres = pg; };"
            toplevel="pg = pkgs.postgresql_16.withPackages (p: with p; [pgvector]);${"\n"}$toplevel"
          fi
          redis=""
          if [ "$with_db_redis" = "1" ]; then
            redis="rd = __rd;${"\n"}rd_shell = __rd_shell;"
          fi
          elixir=""
          if [ "$with_elixir" = "1" ]; then
            elixir="elixir = [elixir${"\n"}(with beamPackages; [${"\n"}hex])(ifIsLinux [inotify-tools]) (ifIsDarwin [ terminal-notifier (with darwin.apple_sdk_12_3.frameworks; [ CoreFoundation CoreServices ])])];"
            toplevel="inherit (pkgs.hax) ifIsLinux ifIsDarwin;${"\n"}$toplevel"
          fi
          golang=""
          if [ "$with_golang" = "1" ]; then
            golang="go = [go${"\n"}go-tools gopls];"
            gitignore="$gitignore${"\n"}# go${"\n"}${gitignore.go}"
          fi
          nim=""
          if [ "$with_nim" = "1" ]; then
            nim="nim = [(nim.withPackages (p: with p; [])) nimble];"
            gitignore="$gitignore${"\n"}# nim${"\n"}${gitignore.nim}"
          fi
          bun=""
          if [ "$with_bun" = "1" ]; then
            bun="bun = [bun];"
            gitignore="$gitignore${"\n"}# bun${"\n"}${gitignore.node}"
          fi
          node=""
          if [ "$with_node" = "1" ]; then
            toplevel="node = pkgs.nodejs_22;${"\n"}$toplevel"
            node="node = [node];"
            gitignore="$gitignore${"\n"}# node${"\n"}${gitignore.node}"
          fi
          php=""
          if [ "$with_php" = "1" ]; then
            php="php = [php83];"
          fi
          dotnet=""
          if [ "$with_dotnet" = "1" ]; then
            dotnet="dotnet = [clang${"\n"}dotnet-sdk_9 dotnet-runtime_9 dotnetPackages.Nuget netcoredbg zlib];"
            extra_env="$extra_env DOTNET_CLI_TELEMETRY_OPTOUT = 1; DOTNET_ROOT = \"\''${pkgs.dotnet-sdk_9}\";"
          fi
          ocaml=""
          if [ "$with_ocaml" = "1" ]; then
            ocaml="ocaml = [bintools${"\n"}clang] ++ (with ocamlPackages; [dream${"\n"}dune_3 findlib ocaml ocaml-lsp ocamlformat]);"
          fi
          pulumi=""
          if [ "$with_pulumi" = "1" ]; then
            py="python = [(python314.withPackages ( p: with p; [${"\n"}pulumi]))];"
            pulumi="pulumi = [pulumi];"
          fi
          py=""
          if [ "$with_python" = "1" ]; then
            py="python = [ruff${"\n"}(python314.withPackages ( p: with p; [${"\n"}black]))];"
            gitignore="$gitignore${"\n"}# python${"\n"}${gitignore.python}"
          fi
          poetry=""
          if [ "$with_poetry" = "1" ]; then
            py="python = [ruff${"\n"}(poetry.override (_: { python3 = python314; }))];"
            poetry="python = pkgs.poetry-helpers.mkEnv {${"\n"}projectDir = ./.; python = pkgs.python314; extraOverrides = [(final: prev: { })];};${"\n"}"
            _env="python.env.overrideAttrs (_: {${"\n"} buildInputs = paths; });"
            gitignore="$gitignore${"\n"}# python${"\n"}${gitignore.python}"
          fi
          ruby=""
          if [ "$with_ruby" = "1" ]; then
            ruby="ruby = [(ruby_3_2.withPackages ( p: with p; []))${"\n"}sqlite];"
          fi
          rust=""
          if [ "$with_rust" = "1" ]; then
            rust_overlay_arg=", _rust ? import${"\n"}  $(${final.nix_hash_rust-overlay}/bin/nix_hash_rust-overlay --fetchtarball)"
            pkgs_import_args="{ overlays = [ _rust ]; }"
            rust="rust = [${"\n"}cargo-zigbuild${"\n"}rust${"\n"}pkg-config${"\n"}openssl${"\n"}];"
            toplevel="target = \"x86_64-unknown-linux-musl\";${"\n"}rust = pkgs.rust-bin.selectLatestNightlyWith (toolchain: toolchain.default.override {${"\n"}extensions = [ \"rust-src\" \"rustc-dev\" \"rust-analyzer\" ];${"\n"}targets = [ target ];${"\n"}});${"\n"}rustPlatform = pkgs.makeRustPlatform {${"\n"}cargo = rust;${"\n"}rustc = rust;${"\n"}};${"\n"}$toplevel"
            gitignore="$gitignore${"\n"}# rust${"\n"}${gitignore.rust}"
          fi
          terraform=""
          if [ "$with_terraform" = "1" ]; then
            terraform="terraform = [terraform${"\n"}terraform-ls terrascan tfsec];"
            gitignore="$gitignore${"\n"}# terraform${"\n"}${gitignore.terraform}${"\n"}"
          fi
          uv=""
          uv_top=""
          if [ "$with_uv" = "1" ]; then
            extra_env_overrides="// uvEnv.uvEnvVars"
            uv="uv = [uv uvEnv];"
            uv_top="uvEnv = pkgs.uv-nix.mkEnv {${"\n"}inherit name; python = pkgs.python314; workspaceRoot = pkgs.hax.filterSrc { path = ./.; }; pyprojectOverrides = final: prev: { }; };${"\n"}"
            gitignore="$gitignore${"\n"}# python${"\n"}${gitignore.python}"
          fi
          vlang=""
          if [ "$with_vlang" = "1" ]; then
            vlang="vlang = [(vlang.withPackages (p: with p; []))];"
          fi
          java=""
          if [ "$with_java" = "1" ]; then
            java="java = [gradle${"\n"}zulu];"
          fi
          if [ "$with_nvidia" = "1" ]; then
            toplevel="deps = with pkgs; [${"\n"}stdenv.cc.cc.lib ] ++ (with cudaPackages; [${"\n"}cudatoolkit]);${"\n"}$toplevel"
            extra_env="$extra_env LD_LIBRARY_PATH = \"\''${pkgs.hax.nvidiaLdPath}:\''${pkgs.lib.makeLibraryPath deps}\";${"\n"}CUDA_PATH = pkgs.cudatoolkit;"
          fi
          ftb="fetchTarball { name = \"$repo_owner-$(date '+%F')\"; url = \"https://github.com/$repo/archive/$rev.tar.gz\"; sha256 = \"$sha\";}"
          if ${h.flag "update"}; then
            default_nix="''${1:-./default.nix}"
            ${h.file.notExists "default_nix"} && die "the nix file to update ('$default_nix') does not exist!"
            echo "updating '$default_nix' to '$repo@$rev'"
            ${_.sed} -i -E -z "s#(fetchTarball[\s]*).*(\/$repo_owner\/$repo_name|nix\.cobi\.dev\/)[^\}]*\}#$ftb#g" "$default_nix"
            ${_.sed} -i -E 's#(fetchTarball \{) (name)#\1\n\2#' "$default_nix"
            ${_.nixpkgs-fmt} "$default_nix" 2>/dev/null
            exit 0
          fi
          if ${h.var.notEmpty "srcpath"}; then
            ftb="$srcpath"
          fi
          ${final.coreutils}/bin/cat -s <<EOF | ${_.sed} -E 's#(fetchTarball \{) (name)#\1\n\2#' | ${_.nixpkgs-fmt}
            { pkgs ? import
                (''${ftb}) ''${pkgs_import_args}
            ''${rust_overlay_arg}
            }:
            let
              name = "$directory";
              ''${toplevel} ''${poetry} ''${uv_top}
              tools = with pkgs; {
                cli = [
                  jfmt
                  nixup
                ]; ''${bun} ''${crystal} ''${elixir} ''${golang} ''${nim} ''${node} ''${ocaml} ''${php} ''${dotnet} ''${java} ''${pulumi} ''${py} ''${ruby} ''${rust} ''${terraform} ''${uv} ''${vlang}
                scripts = pkgs.lib.attrsets.attrValues scripts;
              };

            scripts = with pkgs; {''${pg} ''${redis}};
            paths = pkgs.lib.flatten [ (builtins.attrValues tools) ];
            env = ''${_env}
            in
            (env.overrideAttrs (_: {
              inherit name;
              NIXUP = "${version}"; $extra_env
            }''${extra_env_overrides})) // {inherit scripts;}
          EOF
          if [ ! -f .gitignore ]; then
            echo "$gitignore" > .gitignore
          fi
        '';
    };

  y2n = final.hax.writeBashBinChecked "y2n" ''
    set -euo pipefail

    if [ "$#" -gt 1 ]; then
      echo "usage: y2n [yaml-file|-]" >&2
      exit 64
    fi

    yaml="''${1:--}"

    json_to_nix() {
      json="$1" ${final._nix}/bin/nix eval --raw --impure --expr \
        'with import ${final.pkgs.path} {}; lib.generators.toPretty {} (builtins.fromJSON (builtins.getEnv "json"))'
      printf '\n'
    }

    first=1
    AQ_FLAGS="" ${lib.getExe final.aq} -o json -c '.' -- "$yaml" | while IFS= read -r json; do
      if [ "$first" = "0" ]; then
        printf '\n'
      fi
      first=0
      json_to_nix "$json"
    done
  '';

  nixsum = pog {
    name = "nixsum";
    description = "my lazy helper function to summarize a dir of nix scripts";
    flags = [
      {
        name = "extensions";
        description = "pipe separated list of extensions to use in the summary";
        default = "nix";
      }
      {
        name = "depth";
        description = "how deep to search";
        default = "1";
      }
    ];
    script = ''
      files=$(${_.find} . -maxdepth "$depth" -regextype posix-egrep -regex "\./.*\.($extensions)" | ${_.sort})
      for f in $files; do
          echo -e "### [''${f:2}]($f)\n"
          top=$(${_.grep} "^#" "$f" | ${_.head} -1)
          echo -e "''${top:2}\n"
      done
    '';
  };

  nixcache = pog {
    name = "nixcache";
    description = "a way to cache one or more builds into s3";
    flags = [
      {
        name = "uri";
        description = "the cache uri to copy to (example: s3://nix-cache?region=us-east-2&compression=zstd)";
      }
    ];
    script = ''
      files=( "$@" )
      echo "caching $# builds"
      rm -f ./nixcache.log
      for i in $(${final.coreutils}/bin/seq $#); do
          index=$((i-1))
          ${final._nix}/bin/nix copy --refresh --to "$uri" "''${files[$index]}" >>nixcache.log
          echo "$i"
      done | ${final.python314Packages.tqdm}/bin/tqdm --total "$#" >>/dev/null
      echo "cached $# builds!"
    '';
  };

  nupdate = pog {
    name = "nupdate";
    arguments = [{ name = "attribute"; }];
    description = "my lazy helper function to update an attribute in my nix repo";
    script = ''
      ${final.nix-update}/bin/nix-update --build --flake --use-update-script "$@"
    '';
  };

  nupdate_latest_github = pog {
    name = "nupdate_latest_github";
    arguments = [{ name = "attribute"; }];
    flags = [
      { name = "owner"; description = "the owner of the repo"; }
      { name = "repo"; description = "the repo name"; }
    ];
    description = "";
    script = ''
      latest_tag=$(${final.curl}/bin/curl "https://api.github.com/repos/$owner/$repo/releases/latest" | ${final.jq}/bin/jq -r '.tag_name')
      ${final.nix-update}/bin/nix-update --build --flake --version="$latest_tag" "$@"
    '';
  };

  refresh_codex_latest = pog {
    name = "refresh_codex_latest";
    description = "update codex-latest, refresh Rusty V8 archive, binding, and Cargo hashes, build it, and verify installed runtime helpers";
    flags = [
      {
        name = "version";
        short = "";
        description = "target Codex version, with or without the rust-v prefix; defaults to the latest GitHub release";
      }
      {
        name = "repo";
        envVar = "CFG_REPO";
        description = "cfg checkout to update; defaults to $HOME/cfg";
      }
    ];
    script = ''
      repo="''${repo:-$HOME/cfg}"
      target_file="$repo/mods/final.nix"

      if [ ! -f "$target_file" ]; then
        echo "missing cfg package definition: $target_file" >&2
        exit 2
      fi

      cd "$repo" || exit 1

      if [ -z "$version" ]; then
        latest_tag=$(
          ${final.curl}/bin/curl --fail --silent --show-error \
            https://api.github.com/repos/openai/codex/releases/latest \
            | ${final.jq}/bin/jq -er '.tag_name'
        )
      else
        latest_tag="$version"
      fi

      case "$latest_tag" in
        rust-v*)
          version="''${latest_tag#rust-v}"
          ;;
        v*)
          version="''${latest_tag#v}"
          ;;
        *)
          version="$latest_tag"
          ;;
      esac

      if ! printf '%s\n' "$version" | ${final.gnugrep}/bin/grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+([-.][0-9A-Za-z.]+)?$'; then
        echo "unexpected Codex version: $version" >&2
        exit 2
      fi

      echo "updating codex-latest to $version"
      ${final.nix-update}/bin/nix-update \
        --flake \
        --src-only \
        --version "$version" \
        codex-latest

      source_path=$(${final._nix}/bin/nix eval --raw "path:$repo#codex-latest.src")
      cargo_lock="$source_path/codex-rs/Cargo.lock"
      if [ ! -f "$cargo_lock" ]; then
        echo "missing Codex Cargo.lock: $cargo_lock" >&2
        exit 1
      fi

      v8_version=$(
        ${final.gawk}/bin/awk '
          /^\[\[package\]\]$/ { is_v8 = 0 }
          /^name = "v8"$/ { is_v8 = 1; next }
          is_v8 && /^version = "/ {
            gsub(/^version = "/, "")
            gsub(/"$/, "")
            print
            exit
          }
        ' "$cargo_lock"
      )
      if [ -z "$v8_version" ]; then
        echo "could not determine the Rusty V8 version from $cargo_lock" >&2
        exit 1
      fi

      temp_dir=$(${final.coreutils}/bin/mktemp -d)
      trap '${final.coreutils}/bin/rm -rf "$temp_dir"' EXIT
      declare -A v8_archive_hashes
      declare -A v8_binding_hashes
      v8_release_base="https://github.com/openai/codex/releases/download/rusty-v8-v$v8_version"

      while read -r nix_target rust_target; do
        archive="$temp_dir/librusty_v8_ptrcomp_sandbox_release_$rust_target.a.gz"
        binding="$temp_dir/src_binding_ptrcomp_sandbox_release_$rust_target.rs"
        ${final.curl}/bin/curl --location --fail --silent --show-error \
          --output "$archive" \
          "$v8_release_base/$(${final.coreutils}/bin/basename "$archive")"
        ${final.curl}/bin/curl --location --fail --silent --show-error \
          --output "$binding" \
          "$v8_release_base/$(${final.coreutils}/bin/basename "$binding")"
        v8_archive_hashes["$nix_target"]=$(${final._nix}/bin/nix hash file --type sha256 --sri "$archive")
        v8_binding_hashes["$nix_target"]=$(${final._nix}/bin/nix hash file --type sha256 --sri "$binding")
      done <<'TARGETS'
      aarch64-darwin aarch64-apple-darwin
      aarch64-linux aarch64-unknown-linux-gnu
      x86_64-linux x86_64-unknown-linux-gnu
      TARGETS

      for nix_target in aarch64-darwin aarch64-linux x86_64-linux; do
        v8_archive_hash="''${v8_archive_hashes["$nix_target"]}"
        v8_binding_hash="''${v8_binding_hashes["$nix_target"]}"
        if ! printf '%s\n' "$v8_archive_hash" | ${final.gnugrep}/bin/grep -Eq '^sha256-[A-Za-z0-9+/]{43}=$'; then
          echo "invalid Rusty V8 archive hash for $nix_target: $v8_archive_hash" >&2
          exit 1
        fi
        if ! printf '%s\n' "$v8_binding_hash" | ${final.gnugrep}/bin/grep -Eq '^sha256-[A-Za-z0-9+/]{43}=$'; then
          echo "invalid Rusty V8 binding hash for $nix_target: $v8_binding_hash" >&2
          exit 1
        fi
      done

      for pattern in \
        'v8Version = "' \
        'v8ArchiveHashes = {' \
        'v8BindingHashes = {'
      do
        matches=$(${final.gnugrep}/bin/grep -c "$pattern" "$target_file" || true)
        if [ "$matches" -ne 1 ]; then
          echo "expected one '$pattern' assignment in $target_file, found $matches" >&2
          exit 1
        fi
      done

      V8_VERSION="$v8_version" \
      AARCH64_DARWIN_ARCHIVE_HASH="''${v8_archive_hashes['aarch64-darwin']}" \
      AARCH64_LINUX_ARCHIVE_HASH="''${v8_archive_hashes['aarch64-linux']}" \
      X86_64_LINUX_ARCHIVE_HASH="''${v8_archive_hashes['x86_64-linux']}" \
      AARCH64_DARWIN_BINDING_HASH="''${v8_binding_hashes['aarch64-darwin']}" \
      AARCH64_LINUX_BINDING_HASH="''${v8_binding_hashes['aarch64-linux']}" \
      X86_64_LINUX_BINDING_HASH="''${v8_binding_hashes['x86_64-linux']}" \
        ${final.perl}/bin/perl -0pe '
          (s/(v8Version = ")[^"]+(";)/$1 . $ENV{V8_VERSION} . $2/e) == 1
            or die "expected one v8Version assignment\n";
          (s/(v8ArchiveHashes = \{.*?aarch64-darwin = ")[^"]+(";)/$1 . $ENV{AARCH64_DARWIN_ARCHIVE_HASH} . $2/se) == 1
            or die "expected one aarch64-darwin archive hash\n";
          (s/(v8ArchiveHashes = \{.*?aarch64-linux = ")[^"]+(";)/$1 . $ENV{AARCH64_LINUX_ARCHIVE_HASH} . $2/se) == 1
            or die "expected one aarch64-linux archive hash\n";
          (s/(v8ArchiveHashes = \{.*?x86_64-linux = ")[^"]+(";)/$1 . $ENV{X86_64_LINUX_ARCHIVE_HASH} . $2/se) == 1
            or die "expected one x86_64-linux archive hash\n";
          (s/(v8BindingHashes = \{.*?aarch64-darwin = ")[^"]+(";)/$1 . $ENV{AARCH64_DARWIN_BINDING_HASH} . $2/se) == 1
            or die "expected one aarch64-darwin binding hash\n";
          (s/(v8BindingHashes = \{.*?aarch64-linux = ")[^"]+(";)/$1 . $ENV{AARCH64_LINUX_BINDING_HASH} . $2/se) == 1
            or die "expected one aarch64-linux binding hash\n";
          (s/(v8BindingHashes = \{.*?x86_64-linux = ")[^"]+(";)/$1 . $ENV{X86_64_LINUX_BINDING_HASH} . $2/se) == 1
            or die "expected one x86_64-linux binding hash\n";
        ' "$target_file" > "$temp_dir/final.nix"
      ${final.coreutils}/bin/install -m 0644 "$temp_dir/final.nix" "$target_file"

      ${lib.getExe final.jfmt} "$target_file"
      ${final._nix}/bin/nix-instantiate --parse "$target_file" >/dev/null

      ${final.nix-update}/bin/nix-update \
        --flake \
        --no-src \
        --version skip \
        codex-latest

      ${lib.getExe final.jfmt} "$target_file"
      ${final._nix}/bin/nix-instantiate --parse "$target_file" >/dev/null
      ${final.git}/bin/git diff --check -- "$target_file"

      output=$(
        ${final._nix}/bin/nix build \
          "path:$repo#codex-latest" \
          --no-link \
          --print-build-logs \
          --print-out-paths
      )

      if [ ! -x "$output/bin/codex" ]; then
        echo "built output is missing bin/codex: $output" >&2
        exit 1
      fi
      if [ ! -x "$output/bin/codex-code-mode-host" ]; then
        echo "built output is missing bin/codex-code-mode-host: $output" >&2
        exit 1
      fi

      "$output/bin/codex" --version
      echo "verified codex-code-mode-host in $output/bin"
    '';
  };

  refresh_llama-cpp_latest = pog {
    name = "refresh_llama-cpp_latest";
    description = "update llama-cpp-latest, refresh its source and UI dependency hashes, build it, and verify the CLI and server";
    flags = [
      {
        name = "version";
        short = "";
        description = "target llama.cpp build, with or without the b prefix; defaults to the latest GitHub release";
      }
      {
        name = "repo";
        envVar = "CFG_REPO";
        description = "cfg checkout to update; defaults to $HOME/cfg";
      }
    ];
    script = ''
      repo="''${repo:-$HOME/cfg}"
      target_file="$repo/mods/final.nix"

      if [ ! -f "$target_file" ]; then
        echo "missing cfg package definition: $target_file" >&2
        exit 2
      fi

      cd "$repo" || exit 1

      if [ -z "$version" ]; then
        latest_tag=$(
          ${final.curl}/bin/curl --fail --silent --show-error \
            https://api.github.com/repos/ggml-org/llama.cpp/releases/latest \
            | ${final.jq}/bin/jq -er '.tag_name'
        )
      else
        latest_tag="$version"
      fi

      case "$latest_tag" in
        b*)
          version="''${latest_tag#b}"
          ;;
        *)
          version="$latest_tag"
          ;;
      esac

      if ! printf '%s\n' "$version" | ${final.gnugrep}/bin/grep -Eq '^[0-9]+$'; then
        echo "unexpected llama.cpp build: $version" >&2
        exit 2
      fi

      echo "updating llama-cpp-latest to b$version"
      ${final.nix-update}/bin/nix-update \
        --flake \
        --src-only \
        --version "$version" \
        llama-cpp-latest

      ${lib.getExe final.jfmt} "$target_file"
      ${final._nix}/bin/nix-instantiate --parse "$target_file" >/dev/null

      ${final.nix-update}/bin/nix-update \
        --flake \
        --no-src \
        --version skip \
        llama-cpp-latest

      ${lib.getExe final.jfmt} "$target_file"
      ${final._nix}/bin/nix-instantiate --parse "$target_file" >/dev/null
      ${final.git}/bin/git diff --check -- "$target_file"

      output=$(
        ${final._nix}/bin/nix build \
          "path:$repo#llama-cpp-latest" \
          --no-link \
          --print-build-logs \
          --print-out-paths
      )

      for binary in llama llama-server; do
        if [ ! -x "$output/bin/$binary" ]; then
          echo "built output is missing bin/$binary: $output" >&2
          exit 1
        fi
      done

      "$output/bin/llama" --version
      "$output/bin/llama-server" --version
      echo "verified llama and llama-server in $output/bin"
    '';
  };

  generate_uv_lock = pog {
    name = "generate_uv_lock";
    description = "generate a publishable uv lock from one or more PEP 508 requirements";
    arguments = [ "requirements..." ];
    flags = [
      {
        name = "name";
        short = "";
        description = "artifact name used in the suggested static URL";
      }
      {
        name = "version";
        short = "";
        description = "artifact version used in the suggested static URL";
      }
      {
        name = "project_name";
        short = "";
        description = "synthetic root project name; defaults to the artifact name";
      }
      {
        name = "project_version";
        short = "";
        default = "0.0.0";
        description = "synthetic root project version recorded in the lock";
      }
      {
        name = "python";
        short = "";
        default = "3.13";
        description = "Python minor version used to resolve the lock (3.12, 3.13, or 3.14)";
      }
      {
        name = "requires_python";
        short = "";
        description = "PEP 440 Python constraint; defaults to the selected Python minor";
      }
      {
        name = "output";
        short = "";
        description = "lock path; defaults to NAME.lock in the current directory";
      }
      {
        name = "overrides";
        short = "";
        description = "newline-separated tool.uv override requirements";
      }
      {
        name = "no_dependencies";
        short = "";
        description = "newline-separated exact package pins whose dependency metadata should be ignored";
      }
      {
        name = "public_url";
        short = "";
        envVar = "STATIC_G7C_PUBLIC_URL";
        default = "https://static.g7c.us";
        description = "public artifact base URL used in the printed upload metadata";
      }
    ];
    script = ''
      if [ -z "$name" ]; then
        echo "--name is required" >&2
        exit 2
      fi
      if [ -z "$version" ]; then
        echo "--version is required" >&2
        exit 2
      fi
      project_name="''${project_name:-$name}"
      for value in "$name" "$version" "$project_name" "$project_version"; do
        if ! printf '%s\n' "$value" | ${final.gnugrep}/bin/grep -Eq '^[0-9A-Za-z._+-]+$'; then
          echo "names and versions may contain only letters, numbers, dot, underscore, plus, and hyphen" >&2
          exit 2
        fi
      done
      if [ "$#" -eq 0 ]; then
        echo "at least one PEP 508 requirement is required" >&2
        exit 2
      fi

      case "$python" in
        3.12)
          python_bin=${final.python312}/bin/python3.12
          default_requires_python=">=3.12,<3.13"
          ;;
        3.13)
          python_bin=${final.python313}/bin/python3.13
          default_requires_python=">=3.13,<3.14"
          ;;
        3.14)
          python_bin=${final.python314}/bin/python3.14
          default_requires_python=">=3.14,<3.15"
          ;;
        *)
          echo "unsupported Python minor: $python" >&2
          exit 2
          ;;
      esac
      requires_python="''${requires_python:-$default_requires_python}"
      output="''${output:-$PWD/$name.lock}"

      temp_dir=$(${final.coreutils}/bin/mktemp -d)
      trap '${final.coreutils}/bin/rm -rf "$temp_dir"' EXIT
      {
        ${final.coreutils}/bin/printf '%s\n' \
          '[project]' \
          "name = \"$project_name\"" \
          "version = \"$project_version\"" \
          "requires-python = \"$requires_python\"" \
          'dependencies = ['
        for requirement in "$@"; do
          if [ -z "$requirement" ]; then
            echo "requirements may not be empty" >&2
            exit 2
          fi
          encoded=$(printf '%s' "$requirement" | ${final.jq}/bin/jq -Rs '.')
          printf '  %s,\n' "$encoded"
        done
        printf ']\n'

        if [ -n "$overrides" ]; then
          printf '\n[tool.uv]\noverride-dependencies = [\n'
          while IFS= read -r override || [ -n "$override" ]; do
            [ -z "$override" ] && continue
            encoded=$(printf '%s' "$override" | ${final.jq}/bin/jq -Rs '.')
            printf '  %s,\n' "$encoded"
          done <<<"$overrides"
          printf ']\n'
        fi

        if [ -n "$no_dependencies" ]; then
          while IFS= read -r package_pin || [ -n "$package_pin" ]; do
            [ -z "$package_pin" ] && continue
            case "$package_pin" in
              *==*)
                package_name="''${package_pin%%==*}"
                package_version="''${package_pin#*==}"
                ;;
              *)
                echo "--no_dependencies entries must be exact NAME==VERSION pins: $package_pin" >&2
                exit 2
                ;;
            esac
            if ! printf '%s\n' "$package_name" | ${final.gnugrep}/bin/grep -Eq '^[0-9A-Za-z][0-9A-Za-z._-]*$'; then
              echo "invalid package name in --no_dependencies: $package_name" >&2
              exit 2
            fi
            if ! printf '%s\n' "$package_version" | ${final.gnugrep}/bin/grep -Eq '^[0-9A-Za-z][0-9A-Za-z.!+_-]*$'; then
              echo "invalid package version in --no_dependencies: $package_version" >&2
              exit 2
            fi
            encoded_name=$(printf '%s' "$package_name" | ${final.jq}/bin/jq -Rs '.')
            encoded_version=$(printf '%s' "$package_version" | ${final.jq}/bin/jq -Rs '.')
            printf '\n[[tool.uv.dependency-metadata]]\nname = %s\nversion = %s\nrequires-dist = []\n' \
              "$encoded_name" "$encoded_version"
          done <<<"$no_dependencies"
        fi
      } >"$temp_dir/pyproject.toml"

      UV_PYTHON_DOWNLOADS=never ${lib.getExe final.uv} lock \
        --upgrade \
        --python "$python_bin" \
        --directory "$temp_dir"
      ${final.coreutils}/bin/install -D -m 0644 "$temp_dir/uv.lock" "$output"

      lock_hash=$(${final._nix}/bin/nix hash file --type sha256 --sri "$output")
      artifact_url="''${public_url%/}/lock/uv/$name/$version.lock"
      printf 'name=%s\nversion=%s\nproject_name=%s\nproject_version=%s\npython=%s\nrequires_python=%s\nlock_file=%s\nlock_hash=%s\nlock_url=%s\n' \
        "$name" "$version" "$project_name" "$project_version" "$python" "$requires_python" "$output" "$lock_hash" "$artifact_url"
    '';
  };

  generate_sglang_omni_lock = pog {
    name = "generate_sglang_omni_lock";
    description = "resolve an SGLang-Omni branch, tag, or revision and generate its Python 3.12 uv lock";
    flags = [
      {
        name = "ref";
        short = "";
        default = "main";
        description = "SGLang-Omni branch, tag, or commit to lock";
      }
      {
        name = "output";
        short = "";
        description = "lock path; defaults to pkgs/uv/sglang-omni.lock in the cfg checkout";
      }
      {
        name = "repo";
        short = "";
        envVar = "CFG_REPO";
        description = "cfg checkout containing pkgs/uv; defaults to $HOME/cfg";
      }
      {
        name = "public_url";
        short = "";
        envVar = "STATIC_G7C_PUBLIC_URL";
        default = "https://static.g7c.us";
        description = "public artifact base URL used in the printed upload metadata";
      }
    ];
    script = ''
      repo="''${repo:-$HOME/cfg}"
      output="''${output:-$repo/pkgs/uv/sglang-omni.lock}"
      remote="https://github.com/sgl-project/sglang-omni.git"

      if [ ! -d "$repo/pkgs/uv" ]; then
        echo "missing cfg uv package directory: $repo/pkgs/uv" >&2
        exit 2
      fi
      if ! printf '%s\n' "$ref" | ${final.gnugrep}/bin/grep -Eq '^[0-9A-Za-z._/-]+$'; then
        echo "unexpected SGLang-Omni ref: $ref" >&2
        exit 2
      fi

      tag_name="''${ref#refs/tags/}"
      tag_lines=$(
        ${final.git}/bin/git ls-remote --tags "$remote" \
          "refs/tags/$tag_name" "refs/tags/$tag_name^{}"
      )
      if [ -n "$tag_lines" ]; then
        rev=$(printf '%s\n' "$tag_lines" | ${final.gawk}/bin/awk '
          /\^\{\}$/ { peeled = $1 }
          !/\^\{\}$/ { direct = $1 }
          END { if (peeled != "") print peeled; else print direct }
        ')
        snapshot_version=$(printf '%s' "''${tag_name#v}" | ${final.gnused}/bin/sed -E 's/[^0-9A-Za-z._+-]+/-/g')
      else
        branch_name="''${ref#refs/heads/}"
        rev=$(
          ${final.git}/bin/git ls-remote --heads "$remote" "refs/heads/$branch_name" \
            | ${final.gawk}/bin/awk 'NR == 1 { print $1 }'
        )
        if [ -z "$rev" ]; then
          if ! printf '%s\n' "$ref" | ${final.gnugrep}/bin/grep -Eq '^[0-9a-fA-F]{7,40}$'; then
            echo "SGLang-Omni ref is not a branch, tag, or commit: $ref" >&2
            exit 2
          fi
          rev="$ref"
        fi
        snapshot_version=""
      fi

      commit_json=$(
        ${final.curl}/bin/curl --fail --silent --show-error \
          "https://api.github.com/repos/sgl-project/sglang-omni/commits/$rev"
      )
      rev=$(printf '%s\n' "$commit_json" | ${final.jq}/bin/jq -er '.sha')
      commit_date=$(printf '%s\n' "$commit_json" | ${final.jq}/bin/jq -er '.commit.committer.date | split("T")[0]')
      short_rev=$(printf '%.7s' "$rev")
      if [ -z "$snapshot_version" ]; then
        snapshot_version="unstable-$commit_date-$short_rev"
      fi

      source_url="https://github.com/sgl-project/sglang-omni/archive/$rev.tar.gz"
      ${generate_uv_lock}/bin/generate_uv_lock \
        --name sglang-omni \
        --version "$snapshot_version" \
        --project_name s \
        --python 3.12 \
        --requires_python '>=3.12,<3.13' \
        --output "$output" \
        --overrides 'protobuf>=6.31.1,<7.0.0' \
        --no_dependencies 'qwen-tts==0.1.1' \
        --public_url "$public_url" \
        "sglang-omni @ $source_url" \
        'qwen-tts==0.1.1' \
        sox \
        einops \
        onnxruntime
      printf 'rev=%s\n' "$rev"
    '';
  };

  refresh_zaddy = pog {
    name = "refresh_zaddy";
    description = "refresh zaddy's vendor hash, build it, and verify every configured plugin in the vendored tree and binary";
    flags = [
      {
        name = "repo";
        envVar = "CFG_REPO";
        description = "cfg checkout to update; defaults to $HOME/cfg";
      }
    ];
    script = ''
      repo="''${repo:-$HOME/cfg}"
      target_file="$repo/mods/pkgs/zaddy.nix"

      if [ ! -f "$target_file" ]; then
        echo "missing zaddy package definition: $target_file" >&2
        exit 2
      fi

      cd "$repo" || exit 1
      ${final.nix-update}/bin/nix-update \
        --flake \
        --no-src \
        --version skip \
        zaddy

      ${lib.getExe final.jfmt} "$target_file"
      ${final._nix}/bin/nix-instantiate --parse "$target_file" >/dev/null
      ${final.git}/bin/git diff --check -- "$target_file"

      output=$(
        ${final._nix}/bin/nix build \
          "path:$repo#zaddy" \
          --no-link \
          --print-build-logs \
          --print-out-paths
      )
      modules_output=$(
        ${final._nix}/bin/nix build \
          "path:$repo#zaddy.goModules" \
          --no-link \
          --print-out-paths
      )
      expected_plugins=$(
        ${final._nix}/bin/nix eval \
          --json \
          "path:$repo#zaddy.zaddyPlugins"
      )

      if [ ! -x "$output/bin/caddy" ]; then
        echo "built output is missing bin/caddy: $output" >&2
        exit 1
      fi

      build_info=$("$output/bin/caddy" build-info)
      missing=0
      while IFS= read -r module; do
        [ -z "$module" ] && continue
        if ! printf '%s\n' "$build_info" | ${final.gnugrep}/bin/grep -F -q -- "$module"; then
          echo "missing configured plugin from caddy build-info: $module" >&2
          missing=1
        fi
        if ! ${final.gnugrep}/bin/grep -R -F -q -- "$module" "$modules_output"; then
          echo "missing configured plugin from vendored modules: $module" >&2
          missing=1
        fi
      done < <(printf '%s\n' "$expected_plugins" | ${final.jq}/bin/jq -r '.[].name')

      if [ "$missing" -ne 0 ]; then
        exit 1
      fi

      printf '%s\n' "$build_info"
      echo "verified configured plugins in $modules_output and $output"
    '';
  };

  #  get_latest = "${curl}/bin/curl https://api.github.com/repos/supabase/cli/releases/latest | ${jq}/bin/jq '.tag_name'";

  ndiff = pog {
    name = "ndiff";
    description = "a pog script to diff my repo's attrs vs upstream";
    arguments = [{ name = "attribute"; }];
    flags = [
      { name = "nixpkgs"; default = final.nixpkgsRev; }
    ];
    script = helpers: with helpers; ''
      attribute="$1"
      ${var.empty "attribute"} && die "no attribute specified to diff!"
      ${final.nvd}/bin/nvd diff \
        "$(${final._nix}/bin/nix eval --raw "github:NixOS/nixpkgs/$nixpkgs#$attribute.drvPath")" \
        "$(${final._nix}/bin/nix eval --raw "github:jpetrucciani/nix#$attribute.drvPath")"
    '';
  };

  rehydrate = pog {
    name = "rehydrate";
    description = "a pog script to restore libraries from the nix-store on a binary that's been copied to a new box";
    arguments = [{ name = "binary"; }];
    script = ''
      target="$1"
      paths=$( (${final.patchelf}/bin/patchelf --print-rpath "$target" | ${_.tr} ':' '\n'; ${final.glibc.bin}/bin/ldd "$target" | ${final.gnugrep}/bin/grep -o '/nix/store/[^/ ]*') | ${_.sort} -u)
      for path in $paths; do
          if [ ! -e "$path" ]; then
              echo "fetching missing path: $path"
              ${final._nix}/bin/nix-store -r "$path"
          else
              echo "already exists: $path"
          fi
      done
    '';
  };

  nix_pog_scripts = [
    final.hex
    final.hexcast
    final.nixrender
    ndiff
    nixup
    nixsum
    nixcache
    nupdate
    nupdate_latest_github
    generate_sglang_omni_lock
    generate_uv_lock
    refresh_codex_latest
    refresh_llama-cpp_latest
    refresh_zaddy
    # rehydrate
    y2n
  ];
}
