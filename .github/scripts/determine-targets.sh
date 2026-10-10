#!/bin/bash

set -e

# Determine base commit.
OLD_COMMIT=$(git merge-base ${BASE_SHA} ${HEAD_SHA})
NEW_COMMIT=${HEAD_SHA}
echo "OLD_COMMIT=${OLD_COMMIT}"
echo "NEW_COMMIT=${NEW_COMMIT}"

# Only run pixlet check for apps with Starlark source changes. Manifest,
# preview images, and README edits do not require a render check.
TARGETS=""
while IFS= read -r app; do
  [[ -z "${app}" ]] && continue

  star_changes=$(
    git diff --name-only "${OLD_COMMIT}" "${HEAD_SHA}" -- "${app}/" \
      | grep -E '\.star$' || true
  )

  if [[ -n "${star_changes}" ]]; then
    TARGETS+="${app} "
  else
    echo "Skipping ${app} (no .star file changes)"
  fi
done < <(
  git diff --name-only "${OLD_COMMIT}" "${HEAD_SHA}" \
    | grep '^apps/' \
    | cut -d'/' -f1-2 \
    | sort -u
)

TARGETS="${TARGETS%" "}"
echo "Pixlet check targets: ${TARGETS:-none}"
echo "targets=${TARGETS}" >> "${GITHUB_OUTPUT}"
