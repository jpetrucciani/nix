final: prev:
let
  inherit (final.hax) writeBashBinChecked;
in
{
  scripts = {
    foo = writeBashBinChecked "foo" ''
      echo bar
    '';
    check_doc_links = writeBashBinChecked "check-doc-links" ''
      set -euo pipefail

      broken_links=0

      markdown_files() {
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
          git ls-files | grep -E '\.md$' || true
        else
          find . -type f -name '*.md'
        fi
      }

      while IFS= read -r md; do
        [ -z "$md" ] && continue
        dir="$(dirname "$md")"

        while IFS= read -r match; do
          target="$(printf '%s\n' "$match" | sed -E 's#^.*\(([^)]*)\)$#\1#')"
          target="''${target%%#*}"
          target="''${target%%\?*}"

          case "$target" in
            ""|http*|mailto:*|*://*|\#*)
              continue
              ;;
          esac

          if [ "''${target#/}" != "$target" ]; then
            resolved=".$target"
          else
            resolved="$dir/$target"
          fi

          if [ ! -e "$resolved" ]; then
            printf '%s -> %s\n' "$md" "$target"
            broken_links=$((broken_links + 1))
          fi
        done < <(grep -oE '\[[^]]+\]\(([^)]+)\)' "$md" || true)
      done < <(markdown_files)

      if [ "$broken_links" -ne 0 ]; then
        printf '\nFound %d broken local markdown link(s).\n' "$broken_links" >&2
        exit 1
      fi

      echo "No broken local markdown links found."
    '';
    check_readme_index = writeBashBinChecked "check-readme-index" ''
      set -euo pipefail

      exhaustive_limit="''${README_INDEX_EXHAUSTIVE_LIMIT:-12}"
      issues=0
      tmp_dir="$(mktemp -d)"
      trap 'rm -rf "$tmp_dir"' EXIT
      idx=0

      readme_files() {
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
          git ls-files | grep -E '(^|/)README\.md$' || true
        else
          find . -type f -name 'README.md'
        fi
      }

      while IFS= read -r readme; do
        [ -z "$readme" ] && continue
        if ! grep -q '^## In this directory' "$readme"; then
          continue
        fi

        dir="$(dirname "$readme")"
        doc_entries="$tmp_dir/doc.$idx"
        fs_entries="$tmp_dir/fs.$idx"
        idx=$((idx + 1))

        grep -oE '\[[^]]+\]\(\./[^)]+\)' "$readme" \
          | sed -E 's#^.*\(\./([^)]*)\)$#\1#' \
          | sed 's#/$##' \
          | sed 's#^\./##' \
          | cut -d/ -f1 \
          | sort -u >"$doc_entries" || true

        find "$dir" -mindepth 1 -maxdepth 1 \( -type f -o -type d \) -printf '%f\n' \
          | grep -v '^README.md$' \
          | grep -v '^\.' \
          | sort -u >"$fs_entries"

        entry_count="$(wc -l < "$fs_entries")"
        if [ "$entry_count" -gt "$exhaustive_limit" ]; then
          continue
        fi

        docs_only="$(comm -23 "$doc_entries" "$fs_entries" || true)"
        missing_from_docs="$(comm -13 "$doc_entries" "$fs_entries" || true)"

        if [ -n "$docs_only" ] || [ -n "$missing_from_docs" ]; then
          echo "index drift: $readme"
          if [ -n "$docs_only" ]; then
            while IFS= read -r line; do
              printf '  docs-only: %s\n' "$line"
            done <<<"$docs_only"
          fi
          if [ -n "$missing_from_docs" ]; then
            while IFS= read -r line; do
              printf '  missing-doc: %s\n' "$line"
            done <<<"$missing_from_docs"
          fi
          issues=$((issues + 1))
        fi
      done < <(readme_files)

      if [ "$issues" -ne 0 ]; then
        printf '\nFound %d README index drift issue(s).\n' "$issues" >&2
        exit 1
      fi

      echo "No README index drift issues for directories with <= $exhaustive_limit entries."
    '';
    ci_cache = writeBashBinChecked "ci_cache" ''
      mkdir -p ~/.aws
      echo "$S3_CREDS" | base64 -d >~/.aws/credentials
      echo "$PRIVKEY" | base64 -d >/tmp/cache.priv.pem
      nix run .#nixcache ./result*
      rm /tmp/cache.priv.pem ~/.aws/credentials
    '';
  };
}
