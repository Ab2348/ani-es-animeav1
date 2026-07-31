#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "$0")/.." && pwd)

python3 - "$ROOT" <<'PY'
import os, pathlib, re, subprocess, sys
root = pathlib.Path(sys.argv[1]).resolve()
excluded = {".git", "dist"}
path_patterns = [
    re.compile(rb"/home/[^/\s\"']+"),
    re.compile(rb"/Users/[^/\s\"']+"),
    re.compile(rb"/root/"),
    re.compile(rb"[A-Za-z]:/Users/[^/\s\"']+"),
    re.compile(rb"[A-Za-z]:\\Users\\[^\\\s\"']+"),
]
secret_patterns = [
    re.compile(rb"-----BEGIN [A-Z ]*PRIVATE KEY-----"),
    re.compile(rb"\b(?:AKIA|ASIA)[0-9A-Z]{16}\b"),
    re.compile(rb"\bgh[pousr]_[A-Za-z0-9_]{20,}\b"),
    re.compile(rb"\bgithub_pat_[A-Za-z0-9_]{20,}\b"),
    re.compile(rb"\bglpat-[A-Za-z0-9_-]{20,}\b"),
    re.compile(rb"\bxox[baprs]-[A-Za-z0-9-]{20,}\b"),
    re.compile(rb"\bAIza[0-9A-Za-z_-]{35}\b"),
    re.compile(rb"\b(?:npm_|pypi-)[A-Za-z0-9_-]{20,}\b"),
    re.compile(rb"\b(?:sk|rk)_live_[A-Za-z0-9]{16,}\b"),
    re.compile(rb"(?i)\bauthorization\s*:\s*bearer\s+[A-Za-z0-9._~+/-]{16,}"),
    re.compile(rb"(?i)\b(?:api[_-]?key|client[_-]?secret|access[_-]?token|password|passwd)\s*[:=]\s*['\"]?[A-Za-z0-9._~+/-]{12,}"),
]
email_pattern = re.compile(rb"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}")
anonymous_email = re.compile(rb"(?:noreply|(?:[0-9]+\+)?[^@]+)@users\.noreply\.github\.com", re.I)
forbidden_names = {
    ".ds_store", "thumbs.db", "ehthumbs.db", "desktop.ini", ".netrc",
    ".npmrc", "id_rsa", "id_dsa", "id_ecdsa", "id_ed25519", "kubeconfig",
}
forbidden_parts = {
    ".cache", ".idea", ".vscode", "__pycache__", ".pytest_cache",
    ".mypy_cache", ".ruff_cache",
}
forbidden_suffixes = {".pem", ".p12", ".pfx", ".key", ".log", ".swp", ".tmp"}
problems = []
for path in sorted(root.rglob("*")):
    relative = path.relative_to(root)
    if any(part in excluded for part in relative.parts):
        continue
    lowered_parts = tuple(part.casefold() for part in relative.parts)
    lowered_name = relative.name.casefold()
    if any(part in forbidden_parts for part in lowered_parts):
        problems.append(f"directorio local no permitido: {relative}")
        continue
    if (lowered_name in forbidden_names
            or (lowered_name.startswith(".env") and lowered_name not in {".env.example", ".env.sample", ".env.template"})
            or lowered_name.startswith(("handoff", "handover"))
            or any(lowered_name.endswith(suffix) for suffix in forbidden_suffixes)
            or lowered_name.endswith("~")):
        problems.append(f"archivo local, sensible o de sistema no permitido: {relative}")
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
        if not anonymous_email.fullmatch(email):
            problems.append(f"correo incrustado en {relative}: {email.decode(errors='replace')}")

if subprocess.run(
    ["git", "-C", str(root), "rev-parse", "--is-inside-work-tree"],
    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
).returncode == 0:
    refs = subprocess.run(
        ["git", "-C", str(root), "for-each-ref", "--format=%(refname)",
         "refs/heads", "refs/remotes", "refs/tags"],
        check=True, capture_output=True,
    ).stdout.decode("utf-8", errors="replace").splitlines()
    # actions/checkout guarda el merge efímero de un PR bajo
    # refs/remotes/pull/<n>/merge. No forma parte del historial publicable y
    # GitHub puede crearlo con la identidad privada de quien abrió el PR.
    refs = [ref for ref in refs
            if not re.fullmatch(r"refs/remotes/pull/\d+/(?:head|merge)", ref)]
    identities = []
    if refs:
        identities = subprocess.run(
            ["git", "-C", str(root), "log", "--format=%ae%n%ce", *refs],
            check=True, capture_output=True,
        ).stdout.splitlines()
    tag_identities = subprocess.run(
        ["git", "-C", str(root), "for-each-ref", "--format=%(taggeremail)", "refs/tags"],
        check=True, capture_output=True,
    ).stdout.splitlines()
    for email in identities + [value.strip(b"<>") for value in tag_identities if value]:
        if email and not anonymous_email.fullmatch(email):
            problems.append(f"correo no anonimizado en el historial Git: {email.decode(errors='replace')}")
if problems:
    print("Auditoría de publicación fallida:", file=sys.stderr)
    for problem in sorted(set(problems)):
        print(f"- {problem}", file=sys.stderr)
    raise SystemExit(1)
print("Auditoría de archivos: OK")
PY

printf 'Auditoría de publicación: OK\n'
