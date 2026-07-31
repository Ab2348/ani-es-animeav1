#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "$0")/.." && pwd)
TEST_ROOT=$(mktemp -d)
cleanup_install_test() {
    rm -rf -- "$TEST_ROOT"
}
trap cleanup_install_test EXIT INT TERM HUP

FAKE_BIN="$TEST_ROOT/ruta con espacios/fake-bin"
INSTALL_BIN="$TEST_ROOT/ruta con espacios/install-bin"
STATE_DIR="$TEST_ROOT/ruta con espacios/state/ani-es"
mkdir -p -- "$FAKE_BIN" "$STATE_DIR"

for command_name in fzf mpv; do
    printf '#!/usr/bin/env bash\nexit 0\n' > "$FAKE_BIN/$command_name"
    chmod 0755 "$FAKE_BIN/$command_name"
done

PATH="$FAKE_BIN:$PATH" ANI_ES_INSTALL_DIR="$INSTALL_BIN" "$ROOT/install.sh" >/dev/null
cmp "$ROOT/ani-es" "$INSTALL_BIN/ani-es"
[[ -x "$INSTALL_BIN/ani-es" ]]
[[ $("$INSTALL_BIN/ani-es" --version) == 'ani-es v2.0.0 — proveedor animeav1' ]]
PATH="$FAKE_BIN:$PATH" ANI_ES_INSTALL_DIR="$INSTALL_BIN" "$ROOT/install.sh" >/dev/null

path_message=$(PATH="$FAKE_BIN:$PATH" ANI_ES_INSTALL_DIR="$INSTALL_BIN" "$ROOT/install.sh")
printf '%s\n' "$path_message" | grep -F 'export PATH=' >/dev/null
printf '%s\n' "$path_message" | grep -F '\ ' >/dev/null

ANI_ES_INSTALL_DIR="$INSTALL_BIN" ANI_ES_STATE_DIR="$STATE_DIR" "$ROOT/uninstall.sh" >/dev/null
[[ ! -e "$INSTALL_BIN/ani-es" ]]
[[ -d "$STATE_DIR" ]]

printf '{}\n' > "$STATE_DIR/history.json"
printf 'no borrar\n' > "$STATE_DIR/archivo-ajeno.txt"
ANI_ES_INSTALL_DIR="$INSTALL_BIN" ANI_ES_STATE_DIR="$STATE_DIR" "$ROOT/uninstall.sh" --purge >/dev/null
[[ ! -e "$STATE_DIR/history.json" ]]
[[ -e "$STATE_DIR/archivo-ajeno.txt" ]]

printf '#!/usr/bin/env bash\nprintf "otro programa\\n"\n' > "$INSTALL_BIN/ani-es"
chmod 0755 "$INSTALL_BIN/ani-es"
if PATH="$FAKE_BIN:$PATH" ANI_ES_INSTALL_DIR="$INSTALL_BIN" "$ROOT/install.sh" >/dev/null 2>&1; then
    printf 'El instalador no debe reemplazar un ejecutable ajeno.\n' >&2
    exit 1
fi
if ANI_ES_INSTALL_DIR="$INSTALL_BIN" "$ROOT/uninstall.sh" >/dev/null 2>&1; then
    printf 'El desinstalador no debe borrar un ejecutable ajeno.\n' >&2
    exit 1
fi
[[ -e "$INSTALL_BIN/ani-es" ]]

rm -f -- "$INSTALL_BIN/ani-es"
ln -s -- "$TEST_ROOT/objetivo-inexistente" "$INSTALL_BIN/ani-es"
if PATH="$FAKE_BIN:$PATH" ANI_ES_INSTALL_DIR="$INSTALL_BIN" "$ROOT/install.sh" >/dev/null 2>&1; then
    printf 'El instalador no debe reemplazar un enlace simbólico roto.\n' >&2
    exit 1
fi
if ANI_ES_INSTALL_DIR="$INSTALL_BIN" "$ROOT/uninstall.sh" >/dev/null 2>&1; then
    printf 'El desinstalador no debe eliminar un enlace simbólico no verificable.\n' >&2
    exit 1
fi
[[ -L "$INSTALL_BIN/ani-es" ]]

relative_message=$(
    cd -- "$TEST_ROOT"
    PATH="$FAKE_BIN:$PATH" ANI_ES_INSTALL_DIR='instalación relativa/bin' "$ROOT/install.sh"
)
printf '%s\n' "$relative_message" | grep -F "$TEST_ROOT/instalación relativa/bin/ani-es" >/dev/null
cmp "$ROOT/ani-es" "$TEST_ROOT/instalación relativa/bin/ani-es"
ANI_ES_INSTALL_DIR="$TEST_ROOT/instalación relativa/bin" "$ROOT/uninstall.sh" >/dev/null

printf 'Pruebas de instalación: OK\n'
