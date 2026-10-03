#!/bin/sh
# Build the Flutter web app → static output in build/web.
set -e
FLUTTER_BIN="${FLUTTER_BIN:-/opt/flutter/bin/flutter}"
if [ ! -x "$FLUTTER_BIN" ]; then
  FLUTTER_BIN="$(command -v flutter || true)"
fi
if [ -z "$FLUTTER_BIN" ]; then
  echo "flutter not found" >&2
  exit 1
fi
"$FLUTTER_BIN" build web --no-wasm-dry-run
