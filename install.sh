#!/usr/bin/env bash
set -euo pipefail

if ((BASH_VERSINFO[0] < 4)); then
    printf 'Se requiere Bash 4.0 o posterior.\n' >&2
    exit 1
fi

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
INSTALL_DIR="${ANI_ES_INSTALL_DIR:-$HOME/.local/bin}"
TARGET="$INSTALL_DIR/ani-es"
SOURCE="$SCRIPT_DIR/ani-es"
TEMP_TARGET=""

cleanup_install() {
    [[ -z "$TEMP_TARGET" || ! -e "$TEMP_TARGET" ]] || rm -f -- "$TEMP_TARGET"
}
trap cleanup_install EXIT INT TERM HUP

missing=()
for cmd in bash curl fzf grep sed awk sort jq python3 mpv install mktemp; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done

if ((${#missing[@]})); then
    printf 'Faltan dependencias: %s\n' "${missing[*]}" >&2
    exit 1
fi

bash -n "$SOURCE" || { printf 'El ejecutable no tiene sintaxis Bash válida.\n' >&2; exit 1; }
install -d -m 0755 "$INSTALL_DIR"
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
        printf 'export PATH="%s:$PATH"\n' "$INSTALL_DIR"
        ;;
esac

if ! command -v yt-dlp >/dev/null 2>&1; then
    printf '\nOpcional: instala yt-dlp para habilitar más servidores de video.\n'
fi
