# This overlay allows me to load the custom packages I've built in my [pkgs/](../pkgs/) directory
final: prev:
let
  inherit (builtins) pathExists readDir;
  inherit (prev.lib) escapeShellArg hasSuffix listToAttrs pathIsDirectory removeSuffix;
  inherit (prev.lib.attrsets) collect mapAttrs;
  inherit (prev.pkgs) callPackage;
  mkGitHubReleaseUpdater =
    { pname
    , owner
    , repo
    , dataFile
    , assets
    , tagPrefix ? "v"
    }:
    final.writeShellApplication {
      name = "update-${pname}";
      runtimeInputs = with final; [
        coreutils
        curl
        jq
        nix
      ];
      text = ''
        set -euo pipefail

        data_file=${escapeShellArg dataFile}
        if [[ ! -f "$data_file" ]]; then
          echo "run this updater from the repository root" >&2
          exit 1
        fi

        release_file="$(mktemp)"
        assets_file="$(mktemp)"
        candidate="$(mktemp "$(dirname "$data_file")/.${pname}.json.XXXXXX")"
        cleanup() {
          rm -f -- "$release_file" "$assets_file"
          if [[ -n "$candidate" ]]; then
            rm -f -- "$candidate"
          fi
        }
        trap cleanup EXIT

        curl_args=(
          --fail
          --location
          --silent
          --show-error
          --retry 3
          --header "Accept: application/vnd.github+json"
        )
        if [[ -n "''${GITHUB_TOKEN:-}" ]]; then
          curl_args+=(--header "Authorization: Bearer $GITHUB_TOKEN")
        fi
        curl "''${curl_args[@]}" \
          --output "$release_file" \
          ${escapeShellArg "https://api.github.com/repos/${owner}/${repo}/releases/latest"}

        tag="$(jq -er '.tag_name | select(type == "string" and length > 0)' "$release_file")"
        tag_prefix=${escapeShellArg tagPrefix}
        if [[ -n "$tag_prefix" && "$tag" != "$tag_prefix"* ]]; then
          echo "release tag $tag does not start with expected prefix $tag_prefix" >&2
          exit 1
        fi
        version="''${tag#"$tag_prefix"}"
        if [[ ! "$version" =~ ^[0-9][0-9A-Za-z._-]*$ ]]; then
          echo "invalid release version: $version" >&2
          exit 1
        fi

        jq -er --argjson expected ${escapeShellArg (builtins.toJSON assets)} '
          . as $release |
          $expected | to_entries[] |
          . as $expectedAsset |
          [$release.assets[] | select(.name == $expectedAsset.value)] as $matches |
          if ($matches | length) != 1 then
            error("expected exactly one release asset named \($expectedAsset.value), found \($matches | length)")
          elif ($matches[0].digest | type) != "string" then
            error("release asset \($expectedAsset.value) has no digest")
          elif ($matches[0].digest | test("^sha256:[0-9a-f]{64}$") | not) then
            error("release asset \($expectedAsset.value) has an invalid SHA-256 digest")
          else
            [$expectedAsset.key, $expectedAsset.value, $matches[0].digest] | @tsv
          end
        ' "$release_file" > "$assets_file"

        candidate_json="$(jq -cn --arg version "$version" '{version: $version, artifacts: {}}')"
        while IFS=$'\t' read -r system asset_name digest; do
          sha256="$(nix hash convert --hash-algo sha256 --to sri "$digest")"
          candidate_json="$(
            jq -cn \
              --argjson current "$candidate_json" \
              --arg system "$system" \
              --arg asset_name "$asset_name" \
              --arg sha256 "$sha256" \
              '$current | .artifacts[$system] = {name: $asset_name, sha256: $sha256}'
          )"
        done < "$assets_file"
        printf '%s\n' "$candidate_json" | jq --sort-keys '.' > "$candidate"

        chmod --reference="$data_file" "$candidate"
        if cmp --silent "$data_file" "$candidate"; then
          echo "${pname} is already current at $version"
          exit 0
        fi

        mv -- "$candidate" "$data_file"
        candidate=""
        echo "updated ${pname} to $version"
      '';
    };
  _custom = p:
    if hasSuffix ".nix" p || pathExists (p + "/default.nix")
    then { name = removeSuffix ".nix" (baseNameOf (toString p)); value = p; __stop = true; }
    else
      if pathIsDirectory p
      then mapAttrs (p': _: _custom (p + "/${p'}")) (readDir p)
      else null;
  customSources = listToAttrs (collect (x: x.__stop or false) (_custom ../pkgs));
  custom = mapAttrs (_: p: callPackage p { }) customSources;
in
{
  __j_package_sources = customSources;
  inherit custom mkGitHubReleaseUpdater;
} // custom
