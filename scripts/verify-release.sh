#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "$0")/.." && pwd)
VERSION=$(sed -nE 's/^VERSION="([^"]+)"$/\1/p' "$ROOT/ani-es")
ARCHIVE="${1:-$ROOT/dist/ani-es-animeav1-$VERSION.tar.gz}"
CHECKSUM="${2:-$ARCHIVE.sha256}"

[[ -f "$ARCHIVE" && -f "$CHECKSUM" ]] || {
    printf 'Faltan el archivo o su checksum. Ejecuta make release.\n' >&2
    exit 1
}

python3 - "$ARCHIVE" "$CHECKSUM" "$VERSION" <<'PY'
import hashlib, pathlib, sys, tarfile
archive = pathlib.Path(sys.argv[1])
checksum_file = pathlib.Path(sys.argv[2])
version = sys.argv[3]
expected, expected_name = checksum_file.read_text(encoding="ascii").split()
if expected_name != archive.name:
    raise SystemExit("El nombre del checksum no coincide con el archivo")
digest = hashlib.sha256()
with archive.open("rb") as source:
    for chunk in iter(lambda: source.read(1024 * 1024), b""):
        digest.update(chunk)
if digest.hexdigest() != expected:
    raise SystemExit("SHA-256 incorrecto")
prefix = f"ani-es-animeav1-{version}/"
root_entry = prefix.rstrip("/")
required = {prefix + name for name in ("ani-es", "install.sh", "uninstall.sh", "README.md", "LICENSE")}
with tarfile.open(archive, "r:gz") as bundle:
    names = set()
    for member in bundle.getmembers():
        path = pathlib.PurePosixPath(member.name)
        if path.is_absolute() or ".." in path.parts:
            raise SystemExit(f"Ruta insegura en el paquete: {member.name}")
        if member.name != root_entry and not member.name.startswith(prefix):
            raise SystemExit(f"Prefijo inesperado: {member.name}")
        if not (member.isfile() or member.isdir()):
            raise SystemExit(f"Tipo de archivo no permitido: {member.name}")
        names.add(member.name)
missing = sorted(required - names)
if missing:
    raise SystemExit("Faltan archivos requeridos: " + ", ".join(missing))
print(f"SHA-256 y estructura válidos: {archive.name}")
PY
