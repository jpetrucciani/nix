final: prev:
let
  inherit (final) pog lib;

  repoFlag = {
    name = "repo";
    envVar = "CFG_REPO";
    description = "cfg checkout to update; defaults to $HOME/cfg";
  };

  r2ArtifactFlags = [
    {
      name = "bucket";
      short = "";
      envVar = "STATIC_G7C_R2_BUCKET";
      default = "gemologic-static";
      description = "R2 bucket backing static.g7c.us";
    }
    {
      name = "endpoint";
      short = "";
      envVar = "CLOUDFLARE_R2_ENDPOINT";
      description = "Cloudflare R2 S3 endpoint";
    }
    {
      name = "profile";
      short = "";
      envVar = "CLOUDFLARE_R2_PROFILE";
      default = "cloudflare";
      description = "AWS profile containing the R2 credentials";
    }
    {
      name = "public_url";
      short = "";
      envVar = "STATIC_G7C_PUBLIC_URL";
      default = "https://static.g7c.us";
      description = "public base URL for the published artifact";
    }
  ];

  mkCfgPackageRefresh =
    { name
    , description
    , target
    , flags ? [ ]
    , script
    }:
    pog {
      inherit name description;
      strict = true;
      flags = flags ++ [ repoFlag ];
      script = ''
        source_repo="''${repo:-$HOME/cfg}"
        if [ ! -f "$source_repo/${target}" ]; then
          echo "missing package definition: $source_repo/${target}" >&2
          exit 2
        fi
        source_repo=$(${final.coreutils}/bin/realpath -e -- "$source_repo")
        source_target="$source_repo/${target}"

        temp_dir=$(${final.coreutils}/bin/mktemp -d)
        staged=""
        cleanup() {
          ${final.coreutils}/bin/rm -rf -- "$temp_dir"
          if [ -n "$staged" ] && [ -f "$staged" ]; then
            ${final.coreutils}/bin/rm -f -- "$staged"
          fi
        }
        trap cleanup EXIT

        repo="$temp_dir/repo"
        ${final.coreutils}/bin/cp --archive --reflink=auto "$source_repo" "$repo"
        target_file="$repo/${target}"
        update_file="$temp_dir/packages.nix"
        flake_ref_nix=$(printf 'path:%s' "$repo" | ${final.jq}/bin/jq -Rs .)
        printf '%s\n' \
          '{ system ? builtins.currentSystem, ... }:' \
          "builtins.getAttr system (builtins.getFlake $flake_ref_nix).legacyPackages" \
          > "$update_file"
        cd "$repo"

        format_target() {
          ${lib.getExe final.jfmt} "$target_file"
          ${final._nix}/bin/nix-instantiate --parse "$target_file" >/dev/null
        }

        latest_github_tag() {
          local owner="$1"
          local repository="$2"
          ${final.curl}/bin/curl --fail --silent --show-error \
            "https://api.github.com/repos/$owner/$repository/releases/latest" \
            | ${final.jq}/bin/jq -er '.tag_name'
        }

        nix_update_source() {
          local attribute="$1"
          local version="$2"
          ${final.nix-update}/bin/nix-update \
            --file "$update_file" \
            --override-filename "$target_file" \
            --src-only \
            --version "$version" \
            "$attribute"
          format_target
        }

        nix_update_deps() {
          local attribute="$1"
          ${final.nix-update}/bin/nix-update \
            --file "$update_file" \
            --override-filename "$target_file" \
            --no-src \
            --version skip \
            "$attribute"
          format_target
        }

        build_attr() {
          local attribute="$1"
          ${final._nix}/bin/nix build \
            "path:$repo#$attribute" \
            --no-link \
            --print-build-logs \
            --print-out-paths
        }

        ${script}

        format_target
        ${final.git}/bin/git diff --check -- "$target_file"
        if ${final.diffutils}/bin/cmp --silent -- "$source_target" "$target_file"; then
          echo "${name}: package expression unchanged"
          exit 0
        fi

        staged=$(${final.coreutils}/bin/mktemp "$(${final.coreutils}/bin/dirname "$source_target")/.refresh.XXXXXX")
        ${final.coreutils}/bin/cp -- "$target_file" "$staged"
        ${final.coreutils}/bin/chmod --reference="$source_target" "$staged"
        ${final._nix}/bin/nix-instantiate --parse "$staged" >/dev/null
        ${final.coreutils}/bin/mv -- "$staged" "$source_target"
        staged=""
        echo "${name}: updated ${target}"
      '';
    };

  publishImmutableR2 = ''
    publish_immutable_r2() {
      local source_file="$1"
      local object_key="$2"
      local content_type="$3"
      local object_uri
      local remote_file="$temp_dir/r2-remote"
      local head_error="$temp_dir/r2-head-error"
      local public_file="$temp_dir/r2-public"

      if [ -z "$endpoint" ]; then
        echo "--endpoint or CLOUDFLARE_R2_ENDPOINT is required" >&2
        exit 2
      fi
      if ! printf '%s\n' "$bucket" | ${final.gnugrep}/bin/grep -Eq '^[0-9a-z][0-9a-z.-]+[0-9a-z]$'; then
        echo "invalid R2 bucket: $bucket" >&2
        exit 2
      fi
      if ! printf '%s\n' "$profile" | ${final.gnugrep}/bin/grep -Eq '^[0-9A-Za-z._-]+$'; then
        echo "invalid AWS profile: $profile" >&2
        exit 2
      fi
      case "$public_url" in
        https://*) ;;
        *)
          echo "public URL must use HTTPS: $public_url" >&2
          exit 2
          ;;
      esac

      object_uri="s3://$bucket/$object_key"
      artifact_url="''${public_url%/}/$object_key"
      export AWS_REQUEST_CHECKSUM_CALCULATION=when_required
      export AWS_RESPONSE_CHECKSUM_VALIDATION=when_required
      if ${final.awscli2}/bin/aws \
        --endpoint-url "$endpoint" \
        --profile "$profile" \
        s3api head-object \
        --bucket "$bucket" \
        --key "$object_key" \
        >"$temp_dir/r2-head.json" 2>"$head_error"; then
        ${final.awscli2}/bin/aws \
          --endpoint-url "$endpoint" \
          --profile "$profile" \
          s3 cp \
          --only-show-errors \
          "$object_uri" \
          "$remote_file"
        if ! ${final.diffutils}/bin/cmp --silent -- "$source_file" "$remote_file"; then
          echo "refusing to replace conflicting immutable object: $object_uri" >&2
          exit 1
        fi
        echo "reusing matching immutable artifact: $object_uri"
      else
        if ! ${final.gnugrep}/bin/grep -Eq '\(404\)|Not Found|NoSuchKey' "$head_error"; then
          ${final.coreutils}/bin/cat "$head_error" >&2
          exit 1
        fi
        ${final.awscli2}/bin/aws \
          --endpoint-url "$endpoint" \
          --profile "$profile" \
          s3 cp \
          --only-show-errors \
          --content-type "$content_type" \
          --cache-control 'public, max-age=31536000, immutable' \
          "$source_file" \
          "$object_uri"
        echo "published immutable artifact: $object_uri"
      fi

      ${final.curl}/bin/curl --fail --silent --show-error --location \
        --retry 5 \
        --retry-all-errors \
        --output "$public_file" \
        "$artifact_url"
      if ! ${final.diffutils}/bin/cmp --silent -- "$source_file" "$public_file"; then
        echo "public artifact differs from the generated file: $artifact_url" >&2
        exit 1
      fi
    }
  '';
in
rec {
  refresh_codex_latest = mkCfgPackageRefresh {
    name = "refresh_codex_latest";
    description = "update codex-latest, refresh Rusty V8 archive, binding, and Cargo hashes, build it, and verify installed runtime helpers";
    target = "pkgs/ai/codex-latest.nix";
    flags = [
      {
        name = "version";
        short = "";
        description = "target Codex version, with or without the rust-v prefix; defaults to the latest GitHub release";
      }
    ];
    script = ''
      if [ -z "$version" ]; then
        latest_tag=$(latest_github_tag openai codex)
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
      nix_update_source codex-latest "$version"

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
        '^[[:space:]]*v8Version = "' \
        '^[[:space:]]*v8ArchiveHashes = {' \
        '^[[:space:]]*v8BindingHashes = {'
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
        ' "$target_file" > "$temp_dir/codex-latest.nix"
      ${final.coreutils}/bin/install -m 0644 "$temp_dir/codex-latest.nix" "$target_file"

      format_target
      nix_update_deps codex-latest
      output=$(build_attr codex-latest)

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

  refresh_llama-cpp_latest = mkCfgPackageRefresh {
    name = "refresh_llama-cpp_latest";
    description = "update llama-cpp-latest, refresh its source and UI dependency hashes, build it, and verify the CLI and server";
    target = "pkgs/ai/llama-cpp-latest.nix";
    flags = [
      {
        name = "version";
        short = "";
        description = "target llama.cpp build, with or without the b prefix; defaults to the latest GitHub release";
      }
    ];
    script = ''
      if [ -z "$version" ]; then
        latest_tag=$(latest_github_tag ggml-org llama.cpp)
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
      nix_update_source llama-cpp-latest "$version"
      nix_update_deps llama-cpp-latest
      output=$(build_attr llama-cpp-latest)

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

  refresh_e2b_cli = mkCfgPackageRefresh {
    name = "refresh_e2b_cli";
    description = "generate and publish e2b-cli's npm lock, update the package, build it, and verify the CLI";
    target = "pkgs/cli/e2b-cli/default.nix";
    flags = [
      {
        name = "version";
        short = "";
        description = "target e2b-cli version; defaults to the npm latest tag";
      }
    ] ++ r2ArtifactFlags;
    script = ''
      ${publishImmutableR2}

      if [ -n "$version" ]; then
        if ! printf '%s\n' "$version" | ${final.gnugrep}/bin/grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$'; then
          echo "unexpected e2b-cli version: $version" >&2
          exit 2
        fi
        metadata_url="https://registry.npmjs.org/@e2b%2fcli/$version"
      else
        metadata_url="https://registry.npmjs.org/@e2b%2fcli/latest"
      fi
      metadata=$(
        ${final.curl}/bin/curl --fail --silent --show-error --location --retry 3 \
          "$metadata_url"
      )
      resolved_version=$(printf '%s\n' "$metadata" | ${final.jq}/bin/jq -er '.version')
      if [ -n "$version" ] && [ "$resolved_version" != "$version" ]; then
        echo "npm resolved $resolved_version, expected $version" >&2
        exit 1
      fi
      version="$resolved_version"
      if ! printf '%s\n' "$version" | ${final.gnugrep}/bin/grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$'; then
        echo "unexpected e2b-cli version from npm: $version" >&2
        exit 1
      fi

      tarball_url=$(printf '%s\n' "$metadata" | ${final.jq}/bin/jq -er '.dist.tarball')
      expected_tarball_url="https://registry.npmjs.org/@e2b/cli/-/cli-$version.tgz"
      if [ "$tarball_url" != "$expected_tarball_url" ]; then
        echo "unexpected e2b-cli tarball URL: $tarball_url" >&2
        exit 1
      fi
      expected_integrity=$(printf '%s\n' "$metadata" | ${final.jq}/bin/jq -er '.dist.integrity')
      if ! printf '%s\n' "$expected_integrity" | ${final.gnugrep}/bin/grep -Eq '^sha512-[0-9A-Za-z+/]+={0,2}$'; then
        echo "unexpected e2b-cli tarball integrity: $expected_integrity" >&2
        exit 1
      fi

      archive="$temp_dir/e2b-cli.tgz"
      ${final.curl}/bin/curl --fail --silent --show-error --location --retry 3 \
        --output "$archive" \
        "$tarball_url"
      actual_integrity=$(${final._nix}/bin/nix hash file --type sha512 --sri "$archive")
      if [ "$actual_integrity" != "$expected_integrity" ]; then
        echo "npm tarball integrity mismatch for e2b-cli $version" >&2
        exit 1
      fi

      package_dir="$temp_dir/package"
      ${final.coreutils}/bin/mkdir --parents "$package_dir"
      ${final.gnutar}/bin/tar \
        --extract \
        --gzip \
        --file "$archive" \
        --directory "$package_dir" \
        --strip-components=1 \
        package/package.json
      ${final.coreutils}/bin/mkdir --parents "$temp_dir/npm-home" "$temp_dir/npm-cache"
      (
        cd "$package_dir"
        HOME="$temp_dir/npm-home" \
        npm_config_cache="$temp_dir/npm-cache" \
          ${final.nodejs_24}/bin/npm install \
            --package-lock-only \
            --ignore-scripts \
            --no-audit \
            --no-fund
      )
      lock_file="$package_dir/package-lock.json"
      ${final.jq}/bin/jq -e --arg version "$version" '
        .name == "@e2b/cli"
        and .version == $version
        and .lockfileVersion == 3
        and .packages[""].version == $version
      ' "$lock_file" >/dev/null
      lock_hash=$(${final._nix}/bin/nix hash file --type sha256 --sri "$lock_file")

      object_key="lock/npm/e2b-cli/$version.lock"
      publish_immutable_r2 "$lock_file" "$object_key" application/json

      nix_update_source e2b-cli "$version"
      matches=$(${final.gnugrep}/bin/grep -c '^[[:space:]]*lockHash = "' "$target_file" || true)
      if [ "$matches" -ne 1 ]; then
        echo "expected one lockHash assignment in $target_file, found $matches" >&2
        exit 1
      fi
      LOCK_HASH="$lock_hash" ${final.perl}/bin/perl -0pe '
        (s/(lockHash = ")[^"]+(";)/$1 . $ENV{LOCK_HASH} . $2/e) == 1
          or die "expected one lockHash assignment\n";
      ' "$target_file" > "$temp_dir/e2b-cli.nix"
      ${final.coreutils}/bin/install -m 0644 "$temp_dir/e2b-cli.nix" "$target_file"

      format_target
      nix_update_deps e2b-cli
      output=$(build_attr e2b-cli)
      if [ ! -x "$output/bin/e2b" ]; then
        echo "built output is missing bin/e2b: $output" >&2
        exit 1
      fi
      "$output/bin/e2b" --version
      printf 'lock_hash=%s\nlock_url=%s\n' "$lock_hash" "$artifact_url"
    '';
  };

  mkVllmRefresh =
    { extraDependencies }:
    mkCfgPackageRefresh {
      name = "refresh_vllm";
      description = "generate and publish vLLM's uv lock, then update and evaluate the package";
      target = "pkgs/uv/vllm.nix";
      flags = [
        {
          name = "version";
          short = "";
          description = "target vLLM version; defaults to the latest PyPI release";
        }
      ] ++ r2ArtifactFlags;
      script = ''
        ${publishImmutableR2}

        if [ -n "$version" ]; then
          if ! printf '%s\n' "$version" | ${final.gnugrep}/bin/grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.]+)?$'; then
            echo "unexpected vLLM version: $version" >&2
            exit 2
          fi
          metadata_url="https://pypi.org/pypi/vllm/$version/json"
        else
          metadata_url="https://pypi.org/pypi/vllm/json"
        fi
        metadata=$(
          ${final.curl}/bin/curl --fail --silent --show-error --location --retry 3 \
            "$metadata_url"
        )
        package_name=$(printf '%s\n' "$metadata" | ${final.jq}/bin/jq -er '.info.name')
        if [ "$package_name" != "vllm" ]; then
          echo "PyPI returned unexpected package name: $package_name" >&2
          exit 1
        fi
        resolved_version=$(printf '%s\n' "$metadata" | ${final.jq}/bin/jq -er '.info.version')
        if [ -n "$version" ] && [ "$resolved_version" != "$version" ]; then
          echo "PyPI resolved $resolved_version, expected $version" >&2
          exit 1
        fi
        version="$resolved_version"
        if ! printf '%s\n' "$version" | ${final.gnugrep}/bin/grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.]+)?$'; then
          echo "unexpected vLLM version from PyPI: $version" >&2
          exit 1
        fi

        current_version=$(${final._nix}/bin/nix eval --raw "path:$repo#vllm.version")
        if [ "$current_version" = "$version" ]; then
          echo "vllm is already current at $version"
          exit 0
        fi

        for platform in aarch64 x86_64; do
          if ! printf '%s\n' "$metadata" | ${final.jq}/bin/jq -e \
            --arg prefix "vllm-$version-" \
            --arg platform "$platform" '
              any(.urls[];
                .packagetype == "bdist_wheel"
                and (.filename as $filename
                  | ($filename | startswith($prefix))
                  and ($filename | contains("manylinux"))
                  and ($filename | endswith("_\($platform).whl"))))
            ' >/dev/null; then
            echo "PyPI release $version has no manylinux wheel for $platform" >&2
            exit 1
          fi
        done

        lock_file="$temp_dir/vllm.lock"
        lock_requirements=(
          "vllm==$version"
          ${lib.escapeShellArgs extraDependencies}
        )
        ${lib.getExe final.generate_uv_lock} \
          --name vllm \
          --version "$version" \
          --project_name v \
          --project_version 0.1.0 \
          --python 3.13 \
          --requires_python '>=3.13,<3.14' \
          --output "$lock_file" \
          --public_url "$public_url" \
          "''${lock_requirements[@]}" \
          >/dev/null
        lock_hash=$(${final._nix}/bin/nix hash file --type sha256 --sri "$lock_file")
        if ! printf '%s\n' "$lock_hash" | ${final.gnugrep}/bin/grep -Eq '^sha256-[A-Za-z0-9+/]{43}=$'; then
          echo "invalid generated vLLM lock hash: $lock_hash" >&2
          exit 1
        fi

        object_key="lock/uv/vllm/$version.lock"
        publish_immutable_r2 "$lock_file" "$object_key" application/toml

        for pattern in \
          ', version ? "' \
          ', lockHash ? "'
        do
          matches=$(${final.gnugrep}/bin/grep -F -c "$pattern" "$target_file" || true)
          if [ "$matches" -ne 1 ]; then
            echo "expected one '$pattern' assignment in $target_file, found $matches" >&2
            exit 1
          fi
        done
        VERSION="$version" LOCK_HASH="$lock_hash" ${final.perl}/bin/perl -0pe '
          (s/(, version \? ")[^"]+("\n)/$1 . $ENV{VERSION} . $2/e) == 1
            or die "expected one version default\n";
          (s/(, lockHash \? ")[^"]+("\n)/$1 . $ENV{LOCK_HASH} . $2/e) == 1
            or die "expected one lockHash default\n";
        ' "$target_file" > "$temp_dir/vllm.nix"
        ${final.coreutils}/bin/install -m 0644 "$temp_dir/vllm.nix" "$target_file"

        format_target
        evaluated_version=$(${final._nix}/bin/nix eval --raw "path:$repo#vllm.version")
        evaluated_lock_hash=$(${final._nix}/bin/nix eval --raw "path:$repo#vllm.lockHash")
        if [ "$evaluated_version" != "$version" ]; then
          echo "evaluated vLLM version $evaluated_version does not match $version" >&2
          exit 1
        fi
        if [ "$evaluated_lock_hash" != "$lock_hash" ]; then
          echo "evaluated vLLM lock hash $evaluated_lock_hash does not match $lock_hash" >&2
          exit 1
        fi
        drv_path=$(${final._nix}/bin/nix eval --raw "path:$repo#vllm.drvPath")
        if ! printf '%s\n' "$drv_path" | ${final.gnugrep}/bin/grep -Eq '^/nix/store/[0-9a-z]{32}-.*\.drv$'; then
          echo "unexpected evaluated vLLM derivation path: $drv_path" >&2
          exit 1
        fi

        printf 'lock_hash=%s\nlock_url=%s\ndrv_path=%s\n' "$lock_hash" "$artifact_url" "$drv_path"
      '';
    };

  refresh_zaddy = mkCfgPackageRefresh {
    name = "refresh_zaddy";
    description = "refresh zaddy's vendor hash, build it, and verify every configured plugin in the vendored tree and binary";
    target = "mods/pkgs/zaddy.nix";
    script = ''
      nix_update_deps zaddy
      output=$(build_attr zaddy)
      modules_output=$(build_attr zaddy.goModules)
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

  refresh_pog_scripts = [
    refresh_codex_latest
    refresh_e2b_cli
    refresh_llama-cpp_latest
    refresh_zaddy
  ];
}
