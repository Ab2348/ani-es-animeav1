#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "$0")/.." && pwd)
export ANI_ES_SOURCE_ONLY=1 ANI_ES_HTTP_TIMEOUT=5
export NO_PROXY="${NO_PROXY:+$NO_PROXY,}127.0.0.1,localhost"
export no_proxy="${no_proxy:+$no_proxy,}127.0.0.1,localhost"
# shellcheck source=/dev/null
source "$ROOT/ani-es"
WORKDIR=$(mktemp -d)
SERVER_PID=""
cleanup_test() {
    [[ -z "$SERVER_PID" ]] || kill "$SERVER_PID" 2>/dev/null || true
    rm -rf -- "$WORKDIR"
    WORKDIR=""
}
trap cleanup_test EXIT
BASE_URL=https://animeav1.com

bash -n "$ROOT/ani-es" "$ROOT/install.sh" "$ROOT/uninstall.sh" "$ROOT/tests/run-tests.sh"
[[ $(ANI_ES_SOURCE_ONLY=1 ANI_ES_LANGUAGE=sub bash -c 'source "$1"; printf "%s\n" "$LANGUAGE"' _ "$ROOT/ani-es") == dub ]]

results=$(av1_parse_search_results "$ROOT/tests/fixtures/catalog.html")
grep -F $'https://animeav1.com/media/naruto\tNaruto' <<<"$results" >/dev/null
grep -F $'https://animeav1.com/media/naruto-shippuuden\tNaruto Shippuden' <<<"$results" >/dev/null
[[ $(wc -l <<<"$results") -eq 2 ]]

svelte_results=$(av1_parse_search_results "$ROOT/tests/fixtures/catalog-svelte.html")
grep -F $'https://animeav1.com/media/bleach\tBleach' <<<"$svelte_results" >/dev/null
grep -F $'https://animeav1.com/media/bleach-sennen-kessen-hen\tBleach: Thousand-Year Blood War' <<<"$svelte_results" >/dev/null

meta=$(av1_parse_metadata "$ROOT/tests/fixtures/anime.html")
[[ $(jq -r .total <<<"$meta") == 1171 ]]
[[ $(jq -r .type <<<"$meta") == "TV Anime" ]]
[[ $(jq -r '.episodes["1"]' <<<"$meta") == "https://animeav1.com/media/one-piece/1" ]]

zero_meta=$(av1_parse_metadata "$ROOT/tests/fixtures/anime-zero-episode.html")
[[ $(jq -r .total <<<"$zero_meta") == 1 ]]
[[ $(jq -r '.episodes["1"]' <<<"$zero_meta") == "https://animeav1.com/media/pelicula-episodio-cero/0" ]]
[[ $(jq -r '.episodes["0"] // empty' <<<"$zero_meta") == "" ]]

links=$(av1_parse_episode_links "$ROOT/tests/fixtures/episode.html")
grep -F $'sub\tstream\tHLS\thttps://player.zilla-networks.com/play/test' <<<"$links" >/dev/null
grep -F $'sub\tstream\tPDrain\thttps://pixeldrain.com/u/AbCd123?embed' <<<"$links" >/dev/null
grep -F $'dub\tstream\tMP4Upload\thttps://www.mp4upload.com/embed-test' <<<"$links" >/dev/null

nested=$(av1_parse_episode_links "$ROOT/tests/fixtures/episode-dub-nested.html")
grep -F $'dub\tstream\tHLS\thttps://player.zilla-networks.com/play/dub-real' <<<"$nested" >/dev/null
grep -F $'dub\tdownload\tPDrain\thttps://pixeldrain.com/u/Dub123\t1080p' <<<"$nested" >/dev/null
grep -F $'sub\tstream\tMP4Upload\thttps://www.mp4upload.com/embed-sub.html' <<<"$nested" >/dev/null

[[ $(server_rank 'PDrain https://pixeldrain.com/u/x') == 10 ]]
[[ $(server_rank 'HLS https://player.zilla-networks.com/play/x') == 20 ]]

resolved=$(resolve_candidate_url 'https://pixeldrain.com/u/AbCd123?embed' 'https://animeav1.com/media/x/1')
[[ "$resolved" == $'https://pixeldrain.com/api/file/AbCd123?download\thttps://pixeldrain.com/u/AbCd123?embed\thttps://pixeldrain.com\tfile' ]]

zilla=$(resolve_candidate_url 'https://player.zilla-networks.com/play/abc123' 'https://animeav1.com/media/x/1')
[[ "$zilla" == $'https://player.zilla-networks.com/m3u8/abc123\thttps://player.zilla-networks.com/play/abc123\thttps://player.zilla-networks.com\thls' ]]

! media_url_is_plausible 'https://example.com/assets/index.js'
media_url_is_plausible 'https://example.com/master.m3u8?token=x'
! resolve_candidate_url 'file:///etc/passwd' 'https://animeav1.com/media/x/1'
if probe_direct_media_url 'file:///etc/passwd' '' ''; then
    printf 'Un protocolo local no debe pasar el probe.\n' >&2
    exit 1
fi
[[ "$PROBE_REASON" == 'protocolo no permitido' ]]
[[ $(normalize_playback_position '00:02:03.500') == 123.5 ]]

if ANI_ES_SOURCE_ONLY=1 ANI_ES_UPDATE_URL='http://example.invalid/ani-es' \
    ANI_ES_UPDATE_SHA256='0000000000000000000000000000000000000000000000000000000000000000' \
    bash -c 'source "$1"; update_self' _ "$ROOT/ani-es" >/dev/null 2>&1; then
    printf 'Una actualización sin HTTPS debe rechazarse.\n' >&2
    exit 1
fi

EPISODE_MAP_FILE="$WORKDIR/map.tsv"
printf '1\thttps://animeav1.com/media/one-piece/uno\n' > "$EPISODE_MAP_FILE"
PROVIDER=animeav1
[[ $(provider_episode_url 'https://animeav1.com/media/one-piece' 1) == 'https://animeav1.com/media/one-piece/uno' ]]
[[ $(provider_episode_url 'https://animeav1.com/media/one-piece' 2) == 'https://animeav1.com/media/one-piece/2' ]]

printf '1\thttps://animeav1.com/media/pelicula-episodio-cero/0\n' > "$EPISODE_MAP_FILE"
[[ $(provider_episode_url 'https://animeav1.com/media/pelicula-episodio-cero' 1) == 'https://animeav1.com/media/pelicula-episodio-cero/0' ]]

printf 'Pruebas de parser y resolutores: OK\n'

# Servidor local: los probes nunca dependen de Internet.
PORT_FILE="$WORKDIR/http-port"
RANGE_LOG="$WORKDIR/range.log"
SERVER_LOG="$WORKDIR/http-server.log"
python3 "$ROOT/tests/http-fixture-server.py" "$PORT_FILE" "$RANGE_LOG" 2> "$SERVER_LOG" &
SERVER_PID=$!
for _ in {1..50}; do
    [[ -s "$PORT_FILE" ]] && break
    sleep 0.02
done
if [[ ! -s "$PORT_FILE" ]]; then
    printf 'El servidor HTTP de pruebas no inició.\n' >&2
    [[ ! -s "$SERVER_LOG" ]] || cat -- "$SERVER_LOG" >&2
    exit 1
fi
TEST_BASE="http://127.0.0.1:$(cat "$PORT_FILE")"

if ! probe_hls_url "$TEST_BASE/valid.m3u8" "$TEST_BASE/player" "$TEST_BASE"; then
    printf 'El probe HLS local falló: %s.\n' "$PROBE_REASON" >&2
    exit 1
fi
if [[ "$PROBE_HTTP_STATUS" != 206 ]]; then
    printf 'El probe HLS local devolvió HTTP %s, se esperaba 206.\n' "$PROBE_HTTP_STATUS" >&2
    exit 1
fi
if probe_hls_url "$TEST_BASE/missing.m3u8" "$TEST_BASE/player" "$TEST_BASE"; then
    printf 'Un HLS 404 no debe ser válido.\n' >&2
    exit 1
fi
[[ "$PROBE_REASON" == 'HTTP 404' ]]
if probe_hls_url "$TEST_BASE/invalid.m3u8" "$TEST_BASE/player" "$TEST_BASE"; then
    printf 'HTML no debe ser válido como HLS.\n' >&2
    exit 1
fi
[[ "$PROBE_REASON" == Content-Type\ incompatible:* ]]
probe_direct_media_url "$TEST_BASE/good.mp4" "$TEST_BASE/player" "$TEST_BASE"

# El servidor ignora Range y anuncia 512 KiB: curl debe abortar por límite.
if probe_direct_media_url "$TEST_BASE/large.mp4" "$TEST_BASE/player" "$TEST_BASE"; then
    printf 'El probe no debe descargar un archivo que ignora Range.\n' >&2
    exit 1
fi
grep -F $'/large.mp4\tbytes=0-1023' "$RANGE_LOG" >/dev/null

printf 'Pruebas de probes HTTP: OK\n'

# Ausencia DUB se distingue de filtro de servidor o fallo de host.
original_http_get=$(declare -f http_get)
http_get() { sed -n '1,$p' "$ROOT/tests/fixtures/episode-sub-only.html"; }
LANGUAGE=dub
PREFERRED_SERVER=auto
RESOLVE_STATUS_FILE="$WORKDIR/no-variant-status"
RESOLVE_FAILURES_FILE="$WORKDIR/no-variant-failures"
no_variant=$(av1_resolve_video_candidates 'https://animeav1.com/media/sub-only/10' || true)
[[ -z "$no_variant" ]]
[[ $(cat "$RESOLVE_STATUS_FILE") == NO_VARIANT ]]
eval "$original_http_get"

FAKE_LOG="$WORKDIR/fake-player.log"
FAKE_PLAYER="$WORKDIR/fake-mpv"
export FAKE_LOG ANI_ES_PLAYER="$FAKE_PLAYER"

# El primer stream pasa el probe pero mpv falla; el segundo se reproduce.
printf '%s\n' '#!/usr/bin/env bash' \
    'printf "%s\n" "$*" >> "$FAKE_LOG"' \
    'case "$*" in *valid.m3u8*) exit 2 ;; *) printf "ANI_ES_TIME=42\n"; exit 0 ;; esac' > "$FAKE_PLAYER"
chmod +x "$FAKE_PLAYER"
provider_episode_url() { printf '%s/1\n' "$1"; }
provider_resolve_video_candidates() {
    printf 'HLS\t%s/valid.m3u8\t%s/player\t%s\thls\n' "$TEST_BASE" "$TEST_BASE" "$TEST_BASE"
    printf 'MP4\t%s/good.mp4\t%s/player\t%s\tfile\n' "$TEST_BASE" "$TEST_BASE" "$TEST_BASE"
}
LANGUAGE=sub
: > "$FAKE_LOG"
play_episode 'Prueba' 'https://animeav1.com/media/x' 1 0
[[ "$LAST_POSITION" == 42 ]]
[[ $(wc -l < "$FAKE_LOG") -eq 2 ]]
grep -F -- '--http-header-fields=Origin: http://127.0.0.1:' "$FAKE_LOG" >/dev/null
grep -F -- '/good.mp4' "$FAKE_LOG" >/dev/null

# Un mpv que devolvería 0 nunca se abre si el probe detectó HTML.
printf '%s\n' '#!/usr/bin/env bash' 'printf "%s\n" "$*" >> "$FAKE_LOG"' 'exit 0' > "$FAKE_PLAYER"
provider_resolve_video_candidates() {
    printf 'HLS\t%s/invalid.m3u8\t%s/player\t%s\thls\n' "$TEST_BASE" "$TEST_BASE" "$TEST_BASE"
}
: > "$FAKE_LOG"
if play_episode 'Prueba inválida' 'https://animeav1.com/media/x' 1 0 2> "$WORKDIR/invalid-playback.log"; then
    printf 'Un probe inválido no debe producir éxito.\n' >&2
    exit 1
else
    playback_status=$?
fi
[[ "$playback_status" == 4 ]]
[[ ! -s "$FAKE_LOG" ]]
grep -F 'Content-Type incompatible' "$WORKDIR/invalid-playback.log" >/dev/null

# El estado de variante ausente devuelve 3 y explica DUB de forma explícita.
provider_resolve_video_candidates() {
    printf 'NO_VARIANT\n' > "$RESOLVE_STATUS_FILE"
}
LANGUAGE=dub
if play_episode 'Sin DUB' 'https://animeav1.com/media/x' 16 0 2> "$WORKDIR/no-dub.log"; then
    printf 'La ausencia DUB no debe ser éxito.\n' >&2
    exit 1
else
    no_dub_status=$?
fi
[[ "$no_dub_status" == 3 ]]
grep -F 'El episodio 16 no tiene versión doblada disponible en AnimeAV1.' "$WORKDIR/no-dub.log" >/dev/null

printf 'Pruebas de fallback y estados: OK\n'
printf 'Pruebas: OK\n'
