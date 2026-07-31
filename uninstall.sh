#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${ANI_ES_INSTALL_DIR:-$HOME/.local/bin}"
TARGET="$INSTALL_DIR/ani-es"
STATE_DIR="${ANI_ES_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/ani-es}"

case "${1:-}" in
    ""|--purge) ;;
    -h|--help)
        printf 'Uso: ./uninstall.sh [--purge]\n'
        exit 0
        ;;
    *)
        printf 'Opción desconocida: %s\n' "$1" >&2
        exit 1
        ;;
esac

if [[ -L "$TARGET" ]]; then
    printf 'Se rechazó eliminar %s porque es un enlace simbólico.\n' "$TARGET" >&2
    exit 1
elif [[ -e "$TARGET" ]]; then
    if ! grep -Fq 'ANI_ES_PROJECT="ani-es-animeav1"' "$TARGET"; then
        printf 'Se rechazó eliminar %s: no pertenece a ani-es-animeav1.\n' "$TARGET" >&2
        exit 1
    fi
    rm -f -- "$TARGET"
    printf 'Eliminado %s\n' "$TARGET"
else
    printf 'No había una instalación en %s\n' "$TARGET"
fi

if [[ "${1:-}" == "--purge" ]]; then
    case "$STATE_DIR" in
        ""|/|"$HOME"|"$INSTALL_DIR")
            printf 'Ruta de estado insegura; se rechazó el borrado: %s\n' "$STATE_DIR" >&2
            exit 1
            ;;
    esac
    if [[ ! -d "$STATE_DIR" ]]; then
        printf 'No había historial en %s\n' "$STATE_DIR"
    else
        shopt -s nullglob
        state_files=("$STATE_DIR/history.json" "$STATE_DIR"/history.json.corrupt.*)
        ((${#state_files[@]} == 0)) || rm -f -- "${state_files[@]}"
        if rmdir -- "$STATE_DIR" 2>/dev/null; then
            printf 'Historial eliminado y directorio vacío retirado de %s\n' "$STATE_DIR"
        else
            printf 'Historial eliminado; otros archivos de %s se conservaron.\n' "$STATE_DIR"
        fi
    fi
else
    printf 'El historial se conservó en %s\n' "$STATE_DIR"
fi
