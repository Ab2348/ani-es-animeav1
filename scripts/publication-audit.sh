#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "$0")/.." && pwd)

python3 - "$ROOT" <<'PY'
import os, pathlib, re, sys
root = pathlib.Path(sys.argv[1]).resolve()
excluded = {".git", "dist", "__pycache__", ".cache"}
path_patterns = [
    re.compile(rb"/home/[^/\s]+/"),
    re.compile(rb"/Users/[^/\s]+/"),
    re.compile(rb"[A-Za-z]:\\Users\\[^\\\s]+\\"),
]
secret_patterns = [
    re.compile(rb"-----BEGIN [A-Z ]*PRIVATE KEY-----"),
    re.compile(rb"\bAKIA[0-9A-Z]{16}\b"),
    re.compile(rb"\bgh[pousr]_[A-Za-z0-9_]{20,}\b"),
    re.compile(rb"\bxox[baprs]-[A-Za-z0-9-]{20,}\b"),
]
email_pattern = re.compile(rb"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}")
problems = []
for path in sorted(root.rglob("*")):
    relative = path.relative_to(root)
    if any(part in excluded for part in relative.parts):
        continue
    if path.is_symlink():
        target = os.readlink(path)
        problems.append(f"enlace simbólico no permitido: {relative} -> {target}")
        continue
    if not path.is_file():
        continue
    if path.stat().st_size > 1_000_000:
        problems.append(f"archivo inesperadamente grande: {relative}")
        continue
    data = path.read_bytes()
    # Las expresiones de esta propia auditoría contienen, por definición, los
    # patrones que buscamos. El archivo sigue sujeto a tamaño y symlinks.
    if relative.as_posix() == "scripts/publication-audit.sh":
        continue
    for pattern in path_patterns:
        if pattern.search(data):
            problems.append(f"ruta local en {relative}")
    for pattern in secret_patterns:
        if pattern.search(data):
            problems.append(f"posible secreto en {relative}")
    for email in email_pattern.findall(data):
        if email != b"noreply@users.noreply.github.com":
            problems.append(f"correo incrustado en {relative}: {email.decode(errors='replace')}")
if problems:
    print("Auditoría de publicación fallida:", file=sys.stderr)
    for problem in sorted(set(problems)):
        print(f"- {problem}", file=sys.stderr)
    raise SystemExit(1)
print("Auditoría de archivos: OK")
PY

if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if git -C "$ROOT" log --format='%ae' | grep -Eiv '^(noreply@users\.noreply\.github\.com|[0-9]+\+[^@]+@users\.noreply\.github\.com)$' | grep -q .; then
        printf 'El historial contiene correos no anonimizados.\n' >&2
        exit 1
    fi
fi

printf 'Auditoría de publicación: OK\n'
