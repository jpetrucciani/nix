#!/usr/bin/env bash
# interactively delete local branches, or remote branches when given a remote name
set -euo pipefail

all=$(mktemp)
keep=$(mktemp)
trap 'rm -f "$all" "$keep"' EXIT

if [ $# -eq 0 ]; then
  current=$(git symbolic-ref --quiet --short HEAD || true)
  git for-each-ref --format='%(refname:short)' refs/heads | { grep -vxF -- "$current" || true; } >"$all"
else
  git ls-remote --heads "$1" | awk '{print $2}' | sed 's|^refs/heads/||' >"$all"
fi

if [ ! -s "$all" ]; then
  echo "No branches found to delete (cannot delete current branch)."
  exit 0
fi

cp "$all" "$keep"
cat >>"$keep" <<EOF

#  Remove the branches you would like to delete.

EOF

editor=${EDITOR:-vi}
if ! eval "$editor" '"$keep"'; then
  echo "Unable to open editor '$editor'. Check value of \$EDITOR and try again."
  exit 1
fi

mapfile -t delete < <(grep -vxF -f "$keep" "$all" || true)
if [ ${#delete[@]} -eq 0 ]; then
  echo "Nothing to delete."
  exit 0
fi

if [ $# -eq 0 ]; then
  git branch -D -- "${delete[@]}"
else
  for branch in "${delete[@]}"; do
    git push "$1" ":refs/heads/$branch"
  done
fi
