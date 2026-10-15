#!/usr/bin/env bash
set -euo pipefail

# Download and install pixlet.
PIXLET_VERSION=$(cat ./PIXLET_VERSION | tr -d '[:space:]')
ASSET="pixlet_${PIXLET_VERSION}_linux-amd64.tar.gz"
URL="https://github.com/tronbyt/pixlet/releases/download/${PIXLET_VERSION}/${ASSET}"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
OUT="$TMPDIR/${ASSET}"

echo "Downloading ${URL}"
if ! curl -fSL --retry 3 --retry-delay 2 -o "$OUT" "$URL"; then
  echo "ERROR: download failed for $URL" >&2
  echo "Headers for diagnosis:" >&2
  curl -sI "$URL" || true
  exit 2
fi

if ! gzip -t "$OUT" 2>/dev/null; then
  echo "ERROR: downloaded file is not a valid gzip archive" >&2
  echo "First 300 bytes for debug:" >&2
  head -c 300 "$OUT" | sed -n '1,200p' >&2
  exit 3
fi

echo "Extracting ${ASSET} to /usr/local/bin"
sudo tar -xzf "$OUT" -C /usr/local/bin --strip-components=1
sudo chmod +x /usr/local/bin/pixlet || true

echo "pixlet ${PIXLET_VERSION} installed"
