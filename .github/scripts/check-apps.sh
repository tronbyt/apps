#!/bin/bash

set -e

# Trim quotes in case any were introduced and populate an array.
# determine-targets.sh emits a space-separated list, so normalise any run of
# whitespace to one target per line before reading it in: a bare `readarray`
# splits on newlines only, which collapsed a multi-app list into a single
# bogus path and silently skipped every check on PRs touching 2+ apps.
readarray -t targets_array < <(echo "${TARGETS}" | tr -d '"' | tr -s '[:space:]' '\n' | sed '/^$/d')

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

# Apps that adapt their layout for square (64x64) panels must say so in the
# manifest. Without the flag the app store cannot badge the app, and users
# browsing on a square display cannot filter for it -- the app silently looks
# like a 64x32 app that happens to render.
check_square_flag() {
    local target="$1"
    local manifest="$target/manifest.yaml"
    if [[ ! -f "$manifest" ]]; then
        return 0
    fi

    # Shape-aware apps are identified by the is_square() convention (either a
    # local helper or canvas.is_square()). Apps that render identically at any
    # aspect ratio need no flag.
    if ! grep -rqE 'is_square' "$target" --include='*.star'; then
        return 0
    fi

    local flag
    flag=$(grep -E '^supports64x64:' "$manifest" | head -n1 | sed -E 's/^supports64x64:[[:space:]]*//' | tr -d '\r' | tr '[:upper:]' '[:lower:]')
    if [[ "$flag" == "true" || "$flag" == "yes" || "$flag" == "1" ]]; then
        return 0
    fi

    echo "❌ ${target} adapts its layout for square (64x64) panels, but its manifest"
    echo "   does not declare it. Add the following to ${manifest}:"
    echo ""
    echo "       supports64x64: true"
    echo ""
    return 1
}

if [ -z "${TARGETS}" ]; then
    echo "✔️ No apps modified"
    exit 0
fi

# Check manifest capability flags first: it is cheap, and reporting every
# offending app in one run beats failing on the first.
flag_failures=0
for target in "${targets_array[@]}"; do
    if [[ ! -d "$target" ]]; then
        continue
    fi
    if is_broken_app "$target"; then
        continue
    fi
    if ! check_square_flag "$target"; then
        flag_failures=$((flag_failures + 1))
    fi
done

if [ "$flag_failures" -gt 0 ]; then
    echo "${flag_failures} app(s) are missing a required manifest capability flag."
    exit 1
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
