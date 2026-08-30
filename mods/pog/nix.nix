# This module configures some helper tools for creating new nix environments!
final: prev:
let
  inherit (final) _ pog lib;
  gitignore = import ./ignore.nix;
in
rec {
  nixup =
    let
      version = "0.0.15";
      updatePinFilter = ''
        def blocks:
          [match("fetchTarball\\s*\\{[^{}]*\\}"; "g")];
        def pin_name:
          try capture("name\\s*=\\s*\"(?<name>[^\"]+)\"\\s*;").name catch "";
        . as $source
        | blocks as $blocks
        | [
            $blocks[]
            | select(
                (.string | contains("# nixup: pin=" + $repo + ";"))
                or (.string | contains("github.com/" + $repo + "/archive/"))
                or (.string | contains("codeload.github.com/" + $repo + "/"))
              )
          ] as $exact
        | [
            $blocks[]
            | . as $block
            | ($block.string | pin_name) as $name
            | select(
                ($name | startswith($owner + "-"))
                and (($name | ltrimstr($owner + "-")) | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}$"))
              )
          ] as $legacy
        | [
            $legacy[]
            | select(.string | contains("nix.cobi.dev/"))
          ] as $cached
        | (
            if ($exact | length) > 0 then $exact
            elif (($cached | length) > 0 and ($legacy | length) == 1) then $cached
            else $legacy
            end
          ) as $matches
        | if ($matches | length) != 1 then
            error("expected exactly one pin for " + $repo + ", found " + (($matches | length) | tostring))
          else
            $matches[0] as $match
            | $source[0:$match.offset] + $replacement + $source[($match.offset + $match.length):]
          end
      '';
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
      strict = true;
      flags = [
        { name = "srcpath"; description = "the fs path to import pkgs from if passed. if not passed in, will pin to the latest version of jpetrucciani/nix"; }
        { name = "update"; bool = true; description = "update the pin to jpetrucciani in the given file (argument 1) [default: ./default.nix]"; }
        { name = "repo"; description = "GitHub repo to pin (format: owner/repo)"; default = "jpetrucciani/nix"; }
        { name = "branch"; description = "Branch to pin to"; default = "main"; }
      ] ++ flags;
      shortDefaultFlags = false;
      beforeExit = ''
        if [ -n "''${nixup_update_tmp:-}" ] && [ -f "$nixup_update_tmp" ]; then
          ${final.coreutils}/bin/rm -f -- "$nixup_update_tmp"
        fi
      '';
      script = h:
        ''
          nixup_update_tmp=""
          project_dir="$(${final.coreutils}/bin/pwd -P)"
          directory="$(${final.coreutils}/bin/basename -- "$project_dir")"
          name=$(printf '%s' "$directory" | ${_.sed} -E 's/[^a-zA-Z0-9._-]+/-/g; s/^[._-]+//; s/[._-]+$//')
          if [ -z "$name" ]; then
            name="project"
          fi
          nix_string() {
            printf '%s' "$1" | ${jaq} -Rs .
          }
          name_nix=$(nix_string "$name")
          source_name_nix=$(nix_string "$name-source")

          if ${h.flag "update"} && ${h.var.notEmpty "srcpath"}; then
            die "--update and --srcpath cannot be used together"
          fi

          toplevel=""
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
            extra_env="$extra_env DOTNET_CLI_TELEMETRY_OPTOUT = \"1\"; DOTNET_ROOT = \"\''${pkgs.dotnet-sdk_9}\";"
          fi
          ocaml=""
          if [ "$with_ocaml" = "1" ]; then
            ocaml="ocaml = [bintools${"\n"}clang] ++ (with ocamlPackages; [dream${"\n"}dune_3 findlib ocaml ocaml-lsp ocamlformat]);"
          fi
          py=""
          if [ "$with_python" = "1" ]; then
            py="python = [ruff${"\n"}(python314.withPackages ( p: with p; [${"\n"}black]))];"
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
            uv_top="uvEnv = pkgs.uv-nix.mkEnv {${"\n"}inherit name; python = pkgs.python313; workspaceRoot = pkgs.hax.filterSrc { name = $source_name_nix; path = ./.; }; pyprojectOverrides = final: prev: { }; };${"\n"}"
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
          if ${h.var.notEmpty "srcpath"}; then
            if [ ! -d "$srcpath" ]; then
              die "the source path ('$srcpath') is not a directory"
            fi
            resolved_srcpath="$(${final.coreutils}/bin/realpath -e -- "$srcpath")"
            ftb="builtins.toPath $(nix_string "$resolved_srcpath")"
          else
            remote=$(${final.nix_hash}/bin/nix_hash --repo "$repo" --branch "$branch")
            pin_date=$(printf '%s' "$remote" | ${jaq} -er '.date | select(type == "string")')
            rev=$(printf '%s' "$remote" | ${jaq} -er '.rev | select(type == "string")')
            sha=$(printf '%s' "$remote" | ${jaq} -er '.sha256 | select(type == "string")')
            archive_url=$(printf '%s' "$remote" | ${jaq} -er '.url | select(type == "string")')
            if [[ ! "$pin_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
              die "nix_hash returned an invalid pin date"
            fi
            if [[ ! "$rev" =~ ^[0-9a-f]{40}$ ]]; then
              die "nix_hash returned an invalid revision"
            fi
            if [[ ! "$sha" =~ ^[0-9abcdfghijklmnpqrsvwxyz]{52}$ ]] && [[ ! "$sha" =~ ^sha256-[A-Za-z0-9+/]{43}=$ ]]; then
              die "nix_hash returned an invalid sha256"
            fi
            if [[ ! "$archive_url" =~ ^https://[^[:space:]]+$ ]]; then
              die "nix_hash returned an invalid archive URL"
            fi
            repo_owner="''${repo%%/*}"
            pin_name_nix=$(nix_string "$repo_owner-$pin_date")
            archive_url_nix=$(nix_string "$archive_url")
            sha_nix=$(nix_string "$sha")
            ftb="fetchTarball {${"\n"}# nixup: pin=$repo;${"\n"}name = $pin_name_nix; url = $archive_url_nix; sha256 = $sha_nix;}"
          fi
          if ${h.flag "update"}; then
            default_nix="''${1:-./default.nix}"
            ${h.file.notExists "default_nix"} && die "the nix file to update ('$default_nix') does not exist!"
            default_nix="$(${final.coreutils}/bin/realpath -e -- "$default_nix")"
            # shellcheck disable=SC2016
            updated_content=$(${jaq} -Rsr \
              --arg repo "$repo" \
              --arg owner "$repo_owner" \
              --arg replacement "$ftb" \
              ${lib.escapeShellArg updatePinFilter} \
              "$default_nix")
            default_dir="$(${final.coreutils}/bin/dirname -- "$default_nix")"
            default_name="$(${final.coreutils}/bin/basename -- "$default_nix")"
            nixup_update_tmp="$(${final.coreutils}/bin/mktemp "$default_dir/.$default_name.nixup.XXXXXX")"
            printf '%s\n' "$updated_content" >| "$nixup_update_tmp"
            ${_.nixpkgs-fmt} "$nixup_update_tmp"
            ${final._nix}/bin/nix-instantiate --parse "$nixup_update_tmp" >/dev/null
            ${final.coreutils}/bin/chmod --reference="$default_nix" "$nixup_update_tmp"
            ${final.coreutils}/bin/mv -- "$nixup_update_tmp" "$default_nix"
            nixup_update_tmp=""
            echo "updated '$default_nix' to '$repo@$rev'"
            exit 0
          fi
          ${final.coreutils}/bin/cat -s <<EOF | ${_.sed} -E 's#(fetchTarball \{) (name)#\1\n\2#' | ${_.nixpkgs-fmt}
            { pkgs ? import
                (''${ftb}) ''${pkgs_import_args}
            ''${rust_overlay_arg}
            }:
            let
              name = ''${name_nix};
              ''${toplevel} ''${uv_top}
              envVars = {${"\n"}NIXUP = "${version}"; $extra_env } ''${extra_env_overrides};
              tools = with pkgs; {
                cli = [
                  jfmt
                  nixup
                ]; ''${bun} ''${crystal} ''${elixir} ''${golang} ''${nim} ''${node} ''${ocaml} ''${php} ''${dotnet} ''${java} ''${py} ''${ruby} ''${rust} ''${terraform} ''${uv} ''${vlang}
                scripts = pkgs.lib.attrsets.attrValues scripts;
              };

            scripts = with pkgs; {''${pg} ''${redis}};
            paths = pkgs.lib.flatten [ (builtins.attrValues tools) ];
            env = pkgs.buildEnv {${"\n"} inherit name paths; buildInputs = paths; };
            in
            (env.overrideAttrs (old: {
              inherit name;
              env = (old.env or { }) // envVars;
            })) // {inherit scripts;}
          EOF
          if [ "$with_uv" = "1" ] && [ ! -f pyproject.toml ]; then
            project_name="$name"
            ${final.coreutils}/bin/cat > pyproject.toml <<EOF
          [project]
          name = "$project_name"
          version = "0.0.1"
          description = ""
          authors = []
          requires-python = ">=3.13,<3.14"
          dependencies = []

          [tool.uv]
          package = false

          [tool.pytest.ini_options]
          pythonpath = ["."]

          [dependency-groups]
          dev = [
              "ptpython>=3.0.29",
              "ruff>=0.16.0",
              "ty>=0.0.73"
          ]
          EOF
            echo "created pyproject.toml for '$project_name'" >&2
          fi
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
      ${final._nix}/bin/nix copy \
        --refresh \
        --to "$uri" \
        "''${files[@]}" >>nixcache.log
      echo "cached $# builds!"
    '';
  };

  nupdate = pog {
    name = "nupdate";
    arguments = [{ name = "attribute"; }];
    description = "my lazy helper function to update an attribute in my nix repo";
    script = ''
      if (( $# == 0 )); then
        echo "nupdate: no attribute specified" >&2
        exit 2
      fi
      attribute=$1
      shift

      system=${lib.escapeShellArg final.stdenv.hostPlatform.system}
      forwarded_args=()
      while (( $# > 0 )); do
        case "$1" in
          --system)
            if (( $# < 2 )); then
              echo "nupdate: --system requires a value" >&2
              exit 2
            fi
            system=$2
            forwarded_args+=( "$1" "$2" )
            shift 2
            ;;
          --system=*)
            system="''${1#--system=}"
            forwarded_args+=( "$1" )
            shift
            ;;
          *)
            forwarded_args+=( "$1" )
            shift
            ;;
        esac
      done

      case "$attribute" in
        legacyPackages.* | packages.*)
          ;;
        *)
          attribute="legacyPackages.$system.$attribute"
          ;;
      esac

      attribute_args=( "$attribute" )
      generic_update_args=()
      use_update_script=( --use-update-script )
      if generic_update_args_json=$(
        ${final._nix}/bin/nix eval \
          --json \
          --no-write-lock-file \
          --apply 'script:
            let
              command = script.command or script;
              commands = if builtins.isList command then command else [ command ];
            in
            if
              builtins.length commands >= 1
              && builtins.baseNameOf (toString (builtins.head commands)) == "nix-update"
            then
              map toString (builtins.tail commands)
            else
              null' \
          ".#$attribute.updateScript" \
          2>/dev/null
      ) && [ "$generic_update_args_json" != "null" ]; then
        mapfile -d "" -t generic_update_args < <(
          ${final.jq}/bin/jq --join-output '.[] | ., "\u0000"' <<<"$generic_update_args_json"
        )
        # Keep generic nix-update scripts in this flake context while preserving
        # package-specific arguments such as --version=branch=main.
        attribute_args=()
        use_update_script=()
      fi

      # nix-update imports <nixpkgs> when it runs a flake updateScript.
      NIX_PATH=${lib.escapeShellArg "nixpkgs=${final.flake.inputs.nixpkgs.outPath}"} \
        UPDATE_NIX_ATTR_PATH="$attribute" \
        ${final.nix-update}/bin/nix-update \
        --build \
        --flake \
        "''${use_update_script[@]}" \
        "''${generic_update_args[@]}" \
        "''${attribute_args[@]}" \
        "''${forwarded_args[@]}"
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

  #  get_latest = "${curl}/bin/curl https://api.github.com/repos/supabase/cli/releases/latest | ${jq}/bin/jq '.tag_name'";

  ndiff = pog {
    name = "ndiff";
    description = "compare one local overlay derivation with the pinned upstream nixpkgs derivation";
    arguments = [{ name = "attribute"; }];
    flags = [
      {
        name = "repo";
        short = "";
        envVar = "CFG_REPO";
        description = "cfg checkout to inspect; defaults to the current directory";
      }
      {
        name = "system";
        short = "";
        default = final.stdenv.hostPlatform.system;
        description = "Nix system to compare";
      }
      {
        name = "nixpkgs";
        short = "";
        description = "optional nixpkgs revision to compare instead of the flake input";
      }
    ];
    script = helpers: with helpers; ''
      attribute="$1"
      ${var.empty "attribute"} && die "no attribute specified to diff!"
      repo="''${repo:-$PWD}"
      if [ ! -f "$repo/flake.nix" ]; then
        die "cfg flake not found at '$repo'"
      fi
      repo="$(${final.coreutils}/bin/realpath -e -- "$repo")"

      upstream="path:$repo#pins.nixpkgs.legacyPackages.$system.$attribute.drvPath"
      if ${var.notEmpty "nixpkgs"}; then
        upstream="github:NixOS/nixpkgs/$nixpkgs#legacyPackages.$system.$attribute.drvPath"
      fi
      ${final.nvd}/bin/nvd diff \
        "$(${final._nix}/bin/nix eval --raw --no-write-lock-file "$upstream")" \
        "$(${final._nix}/bin/nix eval --raw --no-write-lock-file "path:$repo#legacyPackages.$system.$attribute.drvPath")"
    '';
  };

  overlay-diff = pog {
    name = "overlay-diff";
    description = "show the top-level attributes declared by this repo's overlays compared with its pinned nixpkgs";
    strict = true;
    flags = [
      {
        name = "repo";
        short = "";
        envVar = "CFG_REPO";
        description = "cfg checkout to inspect; defaults to the current directory";
      }
      {
        name = "system";
        short = "";
        default = final.stdenv.hostPlatform.system;
        description = "Nix system to compare";
      }
      {
        name = "custom";
        bool = true;
        description = "show only packages discovered under pkgs/";
      }
      {
        name = "overrides";
        bool = true;
        description = "show only attributes that also exist in upstream nixpkgs";
      }
      {
        name = "json";
        bool = true;
        description = "emit the filtered manifest as JSON";
      }
    ];
    script = h: ''
      repo="''${repo:-$PWD}"
      if [ ! -f "$repo/flake.nix" ]; then
        die "cfg flake not found at '$repo'"
      fi
      repo="$(${final.coreutils}/bin/realpath -e -- "$repo")"

      manifest=$(
        ${final._nix}/bin/nix eval \
          --json \
          --no-write-lock-file \
          "path:$repo#lib.overlayDelta.$system"
      )
      custom_only=0
      overrides_only=0
      if ${h.flag "custom"}; then
        custom_only=1
      fi
      if ${h.flag "overrides"}; then
        overrides_only=1
      fi
      manifest=$(
        printf '%s\n' "$manifest" | ${final.jq}/bin/jq \
          --argjson custom_only "$custom_only" \
          --argjson overrides_only "$overrides_only" \
          '
            .entries |= map(select(
              ($custom_only == 0 or .custom)
              and ($overrides_only == 0 or .status == "overridden")
            ))
            | .summary = {
                added: ([.entries[] | select(.status == "added")] | length),
                custom: ([.entries[] | select(.custom)] | length),
                declarations: (.entries | length),
                overridden: ([.entries[] | select(.status == "overridden")] | length)
              }
          '
      )

      if ${h.flag "json"}; then
        printf '%s\n' "$manifest"
        exit 0
      fi

      printf '%s\n' "$manifest" | ${final.jq}/bin/jq -r '
        "nixpkgs \(.nixpkgsRev) on \(.system)",
        "\(.summary.declarations) declarations: \(.summary.added) added, \(.summary.overridden) overridden, \(.summary.custom) from pkgs/",
        "",
        "STATUS     SCOPE    ATTRIBUTE                        DECLARATION",
        (.entries[] |
          "\(.status | . + (" " * (10 - length))) "
          + (if .custom then "pkgs/   " else "overlay " end)
          + "\(.name | . + (" " * ([0, 32 - length] | max))) "
          + (.declaration // "-"))
      '
    '';
  };

  overlay-check = pog {
    name = "overlay-check";
    description = "build selected overlay attributes, or every buildable package discovered under pkgs/";
    strict = true;
    arguments = [
      {
        name = "attribute";
        description = "top-level overlay attribute to build";
        variadic = true;
      }
    ];
    flags = [
      {
        name = "repo";
        short = "";
        envVar = "CFG_REPO";
        description = "cfg checkout to test; defaults to the current directory";
      }
      {
        name = "system";
        short = "";
        default = final.stdenv.hostPlatform.system;
        description = "Nix system to build";
      }
      {
        name = "all";
        bool = true;
        description = "build every eligible package discovered under pkgs/";
      }
      {
        name = "dry-run";
        short = "";
        bool = true;
        description = "show what Nix would build without realizing it";
      }
    ];
    script = h: ''
      repo="''${repo:-$PWD}"
      if [ ! -f "$repo/flake.nix" ]; then
        die "cfg flake not found at '$repo'"
      fi
      repo="$(${final.coreutils}/bin/realpath -e -- "$repo")"

      manifest=$(
        ${final._nix}/bin/nix eval \
          --json \
          --no-write-lock-file \
          "path:$repo#lib.overlayDelta.$system"
      )

      attributes=("$@")
      if ${h.flag "all"}; then
        if [ "''${#attributes[@]}" -ne 0 ]; then
          die "--all cannot be combined with explicit attributes"
        fi
        mapfile -t attributes < <(
          ${final._nix}/bin/nix eval \
            --json \
            --no-write-lock-file \
            --apply builtins.attrNames \
            "path:$repo#packages.$system" \
            | ${final.jq}/bin/jq -r '.[]'
        )
      elif [ "''${#attributes[@]}" -eq 0 ]; then
        die "pass one or more overlay attributes, or use --all for eligible pkgs/ packages"
      fi

      installables=()
      for attribute in "''${attributes[@]}"; do
        if ! printf '%s\n' "$manifest" | ${final.jq}/bin/jq \
          --exit-status \
          --arg attribute "$attribute" \
          'any(.entries[]; .name == $attribute)' \
          >/dev/null; then
          die "'$attribute' is not declared by the local overlay stack"
        fi
        installables+=("path:$repo#legacyPackages.$system.$attribute")
      done

      printf 'building %s overlay attribute(s) for %s\n' "''${#installables[@]}" "$system"
      build_args=(
        --keep-going
        --no-link
        --no-write-lock-file
        --print-build-logs
      )
      if ${h.flag "dry_run"}; then
        build_args+=(--dry-run)
      fi
      ${final._nix}/bin/nix build "''${build_args[@]}" "''${installables[@]}"
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
    overlay-check
    overlay-diff
    nixup
    nixsum
    nixcache
    nupdate
    nupdate_latest_github
    generate_sglang_omni_lock
    generate_uv_lock
    # rehydrate
    y2n
  ];
}
