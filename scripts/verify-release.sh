#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "$0")/.." && pwd)
VERSION=$(sed -nE 's/^VERSION="([^"]+)"$/\1/p' "$ROOT/ani-es")
ARCHIVE="${1:-$ROOT/dist/ani-es-animeav1-$VERSION.tar.gz}"
CHECKSUM="${2:-$ARCHIVE.sha256}"
EXECUTABLE="${3:-$ROOT/dist/ani-es-$VERSION}"
EXECUTABLE_CHECKSUM="${4:-$EXECUTABLE.sha256}"

[[ -f "$ARCHIVE" && -f "$CHECKSUM" && -f "$EXECUTABLE" && -f "$EXECUTABLE_CHECKSUM" ]] || {
    printf 'Faltan artefactos de release o sus checksums. Ejecuta make release.\n' >&2
    exit 1
}

python3 - "$ARCHIVE" "$CHECKSUM" "$VERSION" "$EXECUTABLE" "$EXECUTABLE_CHECKSUM" "$ROOT/ani-es" <<'PY'
import hashlib, pathlib, sys, tarfile
archive = pathlib.Path(sys.argv[1])
checksum_file = pathlib.Path(sys.argv[2])
version = sys.argv[3]
executable = pathlib.Path(sys.argv[4])
executable_checksum = pathlib.Path(sys.argv[5])
source_executable = pathlib.Path(sys.argv[6])

def verify_checksum(artifact, checksum):
    fields = checksum.read_text(encoding="ascii").split()
    if len(fields) != 2:
        raise SystemExit(f"Formato de checksum inválido: {checksum.name}")
    expected, expected_name = fields
    if expected_name != artifact.name:
        raise SystemExit(f"El nombre del checksum no coincide con {artifact.name}")
    digest = hashlib.sha256()
    with artifact.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    if digest.hexdigest() != expected:
        raise SystemExit(f"SHA-256 incorrecto: {artifact.name}")

verify_checksum(archive, checksum_file)
verify_checksum(executable, executable_checksum)
if executable.read_bytes() != source_executable.read_bytes():
    raise SystemExit("El ejecutable de release no coincide con ani-es del checkout")
if not executable.read_bytes().startswith(b"#!/usr/bin/env bash\n"):
    raise SystemExit("El ejecutable de release no tiene la cabecera esperada")
if not executable.stat().st_mode & 0o111:
    raise SystemExit("El ejecutable de release no tiene permiso de ejecución")
prefix = f"ani-es-animeav1-{version}/"
root_entry = prefix.rstrip("/")
required = {prefix + name for name in ("ani-es", "install.sh", "uninstall.sh", "README.md", "LICENSE")}
required_executables = {prefix + name for name in ("ani-es", "install.sh", "uninstall.sh")}
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
        if member.mode & 0o7000:
            raise SystemExit(f"Permisos especiales no permitidos: {member.name}")
        if member.mode & 0o002:
            raise SystemExit(f"Archivo escribible por cualquiera: {member.name}")
        if member.name in required_executables and not member.mode & 0o111:
            raise SystemExit(f"Falta permiso de ejecución: {member.name}")
        names.add(member.name)
missing = sorted(required - names)
if missing:
    raise SystemExit("Faltan archivos requeridos: " + ", ".join(missing))
print(f"Artefactos, SHA-256 y estructura válidos para {version}")
PY

bash -n "$EXECUTABLE"
