#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "$0")/.." && pwd)
DIST="$ROOT/dist"

[[ -d "$DIST" ]] || exit 0
find "$DIST" -maxdepth 1 -type f \
    \( -name 'ani-es-animeav1-*.tar.gz' -o -name 'ani-es-animeav1-*.tar.gz.sha256' \
       -o -name 'ani-es-[0-9]*' -o -name 'ani-es-[0-9]*.sha256' \) \
    -delete
rmdir "$DIST" 2>/dev/null || true
