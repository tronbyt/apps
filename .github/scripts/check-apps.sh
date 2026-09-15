#!/bin/bash

set -e

# Trim quotes in case any were introduced and populate an array.
readarray -t targets_array < <(echo "${TARGETS}" | tr -d '"' | awk '{$1=$1};1')

# Override the max runtime for specific apps. This is useful for apps
# that have a longer runtime on cold cache, but perform well when it's
# warm. Should add exceptions sparingly.
declare -A runtime_exceptions
runtime_exceptions["apps/cltlightrail"]="2s"
runtime_exceptions["apps/milbscores"]="15s"
runtime_exceptions["apps/ncaafscores"]="5s"
runtime_exceptions["apps/ncaafstandings"]="5s"
runtime_exceptions["apps/ncaamstandings"]="5s"
runtime_exceptions["apps/ncaanowstandings"]="5s"
runtime_exceptions["apps/ncaanowstandings"]="5s"
runtime_exceptions["apps/ncaawstandings"]="5s"
runtime_exceptions["apps/nflstandings"]="5s"
runtime_exceptions["apps/nhlstandings"]="5s"
runtime_exceptions["apps/acfilmshowtimes"]="5s"
runtime_exceptions["apps/perlinnoise"]="5s"
runtime_exceptions["apps/arcraiderstats"]="3s"
runtime_exceptions["apps/aflscores"]="3s"
runtime_exceptions["apps/weathermap"]="3s"

is_broken_app() {
    local manifest="$1/manifest.yaml"
    if [[ ! -f "$manifest" ]]; then
        return 1
    fi

    local broken
    broken=$(grep -E '^broken:' "$manifest" | head -n1 | sed -E 's/^broken:[[:space:]]*//' | tr -d '\r' | tr '[:upper:]' '[:lower:]')
    [[ "$broken" == "true" || "$broken" == "yes" || "$broken" == "1" ]]
}

if [ -z "${TARGETS}" ]; then
    echo "✔️ No apps modified"
    exit 0
fi

for target in "${targets_array[@]}"; do
    if [[ ! -d "$target" ]]; then
        # app was deleted
        continue
    fi

    if is_broken_app "$target"; then
        echo "⏭️ Skipping broken app: ${target}"
        continue
    fi

    if [ "${runtime_exceptions[$target]}" ]; then
        t=${runtime_exceptions[$target]}
        echo "pixlet check --max-render-time ${t} ${target}"
        pixlet check --max-render-time "${t}" "${target}"
    else
        echo "pixlet check ${target}"
        pixlet check "${target}"
    fi
done
