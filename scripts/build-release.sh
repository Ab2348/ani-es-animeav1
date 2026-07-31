#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

command -v git >/dev/null 2>&1 || { printf 'Falta git.\n' >&2; exit 1; }
command -v gzip >/dev/null 2>&1 || { printf 'Falta gzip.\n' >&2; exit 1; }
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { printf 'Debe ejecutarse dentro del repositorio.\n' >&2; exit 1; }
[[ -z $(git status --porcelain=v1 --untracked-files=normal) ]] || {
    printf 'El árbol Git debe estar limpio y no tener archivos sin seguimiento.\n' >&2
    exit 1
}

VERSION=$(sed -nE 's/^VERSION="([^"]+)"$/\1/p' ani-es)
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]] || {
    printf 'VERSION no es publicable: %s\n' "$VERSION" >&2
    exit 1
}

DIST="$ROOT/dist"
NAME="ani-es-animeav1-$VERSION"
ARCHIVE="$DIST/$NAME.tar.gz"
CHECKSUM="$ARCHIVE.sha256"
TEMP_ARCHIVE="$DIST/.$NAME.tar.gz.tmp"
mkdir -p -- "$DIST"
rm -f -- "$ARCHIVE" "$CHECKSUM" "$TEMP_ARCHIVE"
trap 'rm -f -- "$TEMP_ARCHIVE"' EXIT INT TERM HUP

git archive --format=tar --prefix="$NAME/" HEAD | gzip -n -9 > "$TEMP_ARCHIVE"
mv -- "$TEMP_ARCHIVE" "$ARCHIVE"

python3 - "$ARCHIVE" "$CHECKSUM" <<'PY'
import hashlib, pathlib, sys
archive = pathlib.Path(sys.argv[1])
checksum = pathlib.Path(sys.argv[2])
digest = hashlib.sha256()
with archive.open("rb") as source:
    for chunk in iter(lambda: source.read(1024 * 1024), b""):
        digest.update(chunk)
checksum.write_text(f"{digest.hexdigest()}  {archive.name}\n", encoding="ascii")
PY

printf 'Creado %s\n' "$ARCHIVE"
printf 'Checksum: '
cat "$CHECKSUM"
