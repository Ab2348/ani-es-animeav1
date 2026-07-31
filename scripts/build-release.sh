#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

for dependency in git gzip python3 install; do
    command -v "$dependency" >/dev/null 2>&1 || {
        printf 'Falta %s.\n' "$dependency" >&2
        exit 1
    }
done
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
EXECUTABLE="$DIST/ani-es-$VERSION"
EXECUTABLE_CHECKSUM="$EXECUTABLE.sha256"
TEMP_EXECUTABLE="$DIST/.ani-es-$VERSION.tmp"
mkdir -p -- "$DIST"
rm -f -- "$ARCHIVE" "$CHECKSUM" "$TEMP_ARCHIVE" \
    "$EXECUTABLE" "$EXECUTABLE_CHECKSUM" "$TEMP_EXECUTABLE"
trap 'rm -f -- "$TEMP_ARCHIVE" "$TEMP_EXECUTABLE"' EXIT INT TERM HUP

git archive --format=tar --prefix="$NAME/" HEAD | gzip -n -9 > "$TEMP_ARCHIVE"
mv -- "$TEMP_ARCHIVE" "$ARCHIVE"
install -m 0755 ani-es "$TEMP_EXECUTABLE"
mv -- "$TEMP_EXECUTABLE" "$EXECUTABLE"

python3 - "$ARCHIVE" "$CHECKSUM" "$EXECUTABLE" "$EXECUTABLE_CHECKSUM" <<'PY'
import hashlib, pathlib, sys
for artifact_arg, checksum_arg in zip(sys.argv[1::2], sys.argv[2::2]):
    artifact = pathlib.Path(artifact_arg)
    checksum = pathlib.Path(checksum_arg)
    digest = hashlib.sha256()
    with artifact.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    checksum.write_text(f"{digest.hexdigest()}  {artifact.name}\n", encoding="ascii")
PY

printf 'Creado %s\n' "$ARCHIVE"
printf 'Checksum: '
cat "$CHECKSUM"
printf 'Creado %s\n' "$EXECUTABLE"
printf 'Checksum: '
cat "$EXECUTABLE_CHECKSUM"
