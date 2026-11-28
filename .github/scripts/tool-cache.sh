#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.."

operation=${1:-}
tool=${2:-}
case "$operation" in
key | restore | run | publish) ;;
*)
  echo "Usage: bash $0 {key|restore|run|publish} TOOL [ARGS...]" >&2
  exit 2
  ;;
esac

system=x86_64-linux
cache=${NIX_TOOL_BINARY_CACHE:-https://cache.g7c.us}
static_url=${STATIC_G7C_PUBLIC_URL:-https://static.g7c.us}
recipe=(flake.nix flake.lock)
name_pattern=$tool
case "$tool" in
jfmt)
  recipe+=(mods/jfmt.nix)
  target="formatter.$system"
  fallback=jfmt
  cache=${JFMT_BINARY_CACHE:-$cache}
  ;;
check-doc-links | check-readme-index | check-vale)
  recipe+=(mods/ci-tools.nix mods/hax.nix scripts.nix)
  if [[ $tool == check-vale ]]; then
    recipe+=(mods/final.nix)
  fi
  attribute=${tool//-/_}
  target="lib.ciTools.$system.$attribute"
  ;;
nupdate)
  recipe+=(mods/ci-tools.nix mods/final.nix mods/pog/nix.nix)
  target="lib.ciTools.$system.nupdate"
  name_pattern='nupdate-[0-9][a-zA-Z0-9._+-]*'
  ;;
iets)
  recipe+=(mods/ci-tools.nix pkgs/cli/iets.nix)
  target="lib.ciTools.$system.iets"
  name_pattern='iets-[0-9][a-zA-Z0-9._+-]*'
  ;;
*)
  echo "Unknown cached tool: $tool" >&2
  exit 2
  ;;
esac
shift 2

checksum=$(
  {
    printf '%s\n' "$system"
    sha256sum "${recipe[@]}"
    if [[ $tool == check-vale ]]; then
      # The wrapper embeds the tracked custom vocabulary.
      git ls-files --stage -- .github/styles/config
      git ls-files -z -- .github/styles/config | xargs -0 -r sha256sum
    fi
  } | sha256sum
)
key=${checksum%% *}
object_key="tools/$tool/$system/$key.json"
manifest_url="${static_url%/}/$object_key"

read_pin() {
  curl --fail --silent --connect-timeout 3 --max-time 8 "$manifest_url" |
    jq -er --arg key "$key" --arg system "$system" --arg name "$name_pattern" '
      select(.key == $key and .system == $system)
      | .storePath | strings
      | select(test("^/nix/store/[0-9abcdfghijklmnpqrsvwxyz]{32}-" + $name + "$"))
    '
}

restore() {
  local store_path
  store_path=$(read_pin) &&
    nix copy --from "$cache" "$store_path" >&2 &&
    [[ -x "$store_path/bin/$tool" ]] &&
    printf '%s\n' "$store_path/bin/$tool"
}

verify_closure() {
  nix store verify --refresh --store "$cache" --recursive --no-contents --sigs-needed 1 "$1"
}

case "$operation" in
key)
  printf '%s\n' "$key"
  ;;
restore)
  restore
  ;;
run)
  if executable=$(restore); then
    echo "Using cached $tool for $key"
    exec "$executable" "$@"
  fi
  echo "Using the checkout's $tool for $key"
  exec nix --show-trace run --no-write-lock-file ".#${fallback:-$target}" -- "$@"
  ;;
publish)
  pin=$(read_pin || true)
  if [[ -n $pin ]] && verify_closure "$pin"; then
    echo "$tool is already published at $manifest_url"
    exit 0
  fi
  if [[ -z $pin ]]; then
    : "${JFMT_ENDPOINT_URL:?Set the R2 endpoint for static.g7c.us}"
    : "${JFMT_ACCESS_KEY_ID:?Set the R2 access key for static.g7c.us}"
    : "${JFMT_SECRET_ACCESS_KEY:?Set the R2 secret key for static.g7c.us}"
  fi

  work_dir=$(mktemp -d)
  trap 'rm -rf -- "$work_dir"' EXIT
  store_path=$(nix build --no-write-lock-file --out-link "$work_dir/result" --print-out-paths ".#$target")
  if [[ -n $pin && $pin != "$store_path" ]]; then
    echo "The published $tool path differs for recipe key $key" >&2
    exit 1
  fi
  if [[ ! -x "$store_path/bin/$tool" ]]; then
    echo "The $tool output is missing its executable" >&2
    exit 1
  fi
  CI_ARCHIVE_FLAKE=false nix run --no-write-lock-file .#scripts.ci_cache -- "$store_path"
  verify_closure "$store_path"
  if [[ -n $pin ]]; then
    echo "Restored the cached closure for $manifest_url"
    exit 0
  fi

  manifest="$work_dir/manifest.json"
  jq -n --arg key "$key" --arg system "$system" --arg path "$store_path" --arg rev "$(git rev-parse HEAD)" \
    '{ key: $key, system: $system, storePath: $path, sourceRev: $rev }' >"$manifest"
  AWS_ACCESS_KEY_ID="$JFMT_ACCESS_KEY_ID" \
    AWS_SECRET_ACCESS_KEY="$JFMT_SECRET_ACCESS_KEY" \
    AWS_REGION=auto AWS_REQUEST_CHECKSUM_CALCULATION=when_required AWS_RESPONSE_CHECKSUM_VALIDATION=when_required \
    aws --endpoint-url "$JFMT_ENDPOINT_URL" s3api put-object \
    --bucket "${JFMT_S3_BUCKET:-gemologic-static}" --key "$object_key" \
    --if-none-match '*' --body "$manifest" --content-type application/json \
    --cache-control 'public, max-age=31536000, immutable' >/dev/null
  echo "Published $manifest_url"
  ;;
esac
