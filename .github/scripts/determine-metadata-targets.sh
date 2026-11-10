#!/bin/bash

set -e

# Find apps changed between BASE_SHA and HEAD_SHA that have edits beyond
# manifest.yaml (e.g. category/tag-only manifest changes should not bump updated).

OLD_COMMIT=$(git merge-base "${BASE_SHA}" "${HEAD_SHA}")
echo "OLD_COMMIT=${OLD_COMMIT}"
echo "NEW_COMMIT=${HEAD_SHA}"

TARGETS=""
while IFS= read -r app; do
  [[ -z "${app}" ]] && continue

  other_changes=$(
    git diff --name-only "${OLD_COMMIT}" "${HEAD_SHA}" -- "${app}/" \
      | grep -vE '/manifest\.yaml$' || true
  )

  if [[ -n "${other_changes}" ]]; then
    TARGETS+="${app} "
  else
    echo "Skipping ${app} (manifest-only changes)"
  fi
done < <(
  git diff --name-only "${OLD_COMMIT}" "${HEAD_SHA}" \
    | grep '^apps/' \
    | cut -d'/' -f1-2 \
    | sort -u
)

TARGETS="${TARGETS%" "}"
echo "Metadata update targets: ${TARGETS:-none}"
echo "targets=${TARGETS}" >> "${GITHUB_OUTPUT}"
