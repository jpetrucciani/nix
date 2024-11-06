#!/bin/bash
# shellcheck disable=SC2181
all=.git-trim-all
keep=.git-trim-keep

cleanup() {
  rm $all $keep
}

if [ $# -eq 0 ]; then
  branches=$(git branch)
else
  branches=$(git ls-remote --heads "$1" | awk '{print $2}' | awk 'BEGIN { FS = "/" } ; {print $3}')
fi

if [ $? != 0 ]; then
  exit 1
fi

# shellcheck disable=SC2063
echo "$branches" | grep -v '^*' | sed 's/^  //' | tee $all $keep >/dev/null

if [ "$(wc -l <$all)" == 0 ]; then
  echo "No branches found to delete (cannot delete current branch)."
  cleanup
  exit 0
fi

cat >>$keep <<EOF

#  Remove the branches you would like to delete.

EOF

eval "$EDITOR" "$keep"

if [ $? != 0 ]; then
  echo "Unable to open editor '$EDITOR'. Check value of \$EDITOR and try again."
  cleanup
  exit 1
fi

delete=$(diff --suppress-common-lines $all $keep | grep '^< ' | awk '{print $2}')

if [ $# -eq 0 ]; then
  # shellcheck disable=SC2086
  echo $delete | xargs git branch -D
else
  for branch in $delete; do
    git push "$1" ":$branch"
  done
fi

cleanup
