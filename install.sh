#!/usr/bin/env bash
set -euo pipefail

if ((BASH_VERSINFO[0] < 4)); then
    printf 'Se requiere Bash 4.0 o posterior.\n' >&2
    exit 1
fi

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
INSTALL_DIR="${ANI_ES_INSTALL_DIR:-$HOME/.local/bin}"
SOURCE="$SCRIPT_DIR/ani-es"
TEMP_TARGET=""

case "$INSTALL_DIR" in
    -*)
        printf 'ANI_ES_INSTALL_DIR no puede comenzar con "-": %s\n' "$INSTALL_DIR" >&2
        exit 1
        ;;
esac

[[ -f "$SOURCE" && ! -L "$SOURCE" ]] || {
    printf 'No se encontró un ejecutable ani-es regular junto al instalador.\n' >&2
    exit 1
}

cleanup_install() {
    [[ -z "$TEMP_TARGET" || ! -e "$TEMP_TARGET" ]] || rm -f -- "$TEMP_TARGET"
}
trap cleanup_install EXIT INT TERM HUP

player="${ANI_ES_PLAYER:-mpv}"
missing=()
for cmd in bash curl fzf grep sed awk sort jq python3 install mktemp head tail tr date "$player"; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done

if ((${#missing[@]})); then
    printf 'Faltan dependencias: %s\n' "${missing[*]}" >&2
    exit 1
fi

bash -n "$SOURCE" || { printf 'El ejecutable no tiene sintaxis Bash válida.\n' >&2; exit 1; }
install -d -m 0755 "$INSTALL_DIR"
INSTALL_DIR=$(cd -- "$INSTALL_DIR" && pwd -P)
TARGET="$INSTALL_DIR/ani-es"
if [[ -L "$TARGET" ]]; then
    printf 'Se rechazó reemplazar %s porque es un enlace simbólico.\n' "$TARGET" >&2
    exit 1
fi
if [[ -e "$TARGET" ]] && ! grep -Fq 'ANI_ES_PROJECT="ani-es-animeav1"' "$TARGET"; then
    printf 'Se rechazó reemplazar %s porque pertenece a otro programa.\n' "$TARGET" >&2
    exit 1
fi
TEMP_TARGET=$(mktemp "$INSTALL_DIR/.ani-es.XXXXXX")
install -m 0755 "$SOURCE" "$TEMP_TARGET"
mv -- "$TEMP_TARGET" "$TARGET"
TEMP_TARGET=""
printf 'ani-es-animeav1 instalado en %s\n' "$TARGET"

case ":$PATH:" in
    *":$INSTALL_DIR:"*) ;;
    *)
        printf '\n%s no está en PATH. Añade esta línea al archivo de inicio de tu shell:\n' "$INSTALL_DIR"
        printf 'export PATH=%q:$PATH\n' "$INSTALL_DIR"
        ;;
esac

if ! command -v yt-dlp >/dev/null 2>&1; then
    printf '\nOpcional: instala yt-dlp para habilitar más servidores de video.\n'
fi
