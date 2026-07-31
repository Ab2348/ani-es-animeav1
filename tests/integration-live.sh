#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "$0")/.." && pwd)
export ANI_ES_SOURCE_ONLY=1
# shellcheck source=/dev/null
source "$ROOT/ani-es"

PROVIDER=animeav1
LANGUAGE="${ANI_ES_LIVE_LANGUAGE:-dub}"
PREFERRED_SERVER="${ANI_ES_LIVE_SERVER:-auto}"
BASE_URL=https://animeav1.com
EPISODE_URL="${ANI_ES_LIVE_URL:-https://animeav1.com/media/kusuriya-no-hitorigoto-2nd-season/16}"
WORKDIR=$(mktemp -d "${TMPDIR:-/tmp}/ani-es-live.XXXXXX")

cleanup_live() {
    if [[ "${ANI_ES_KEEP_WORKDIR:-0}" == 1 ]]; then
        printf 'WORKDIR conservado en %s\n' "$WORKDIR" >&2
    else
        rm -rf -- "$WORKDIR"
        WORKDIR=""
    fi
}
trap cleanup_live EXIT

provider_init
RESOLVE_STATUS_FILE="$WORKDIR/resolve-status"
RESOLVE_FAILURES_FILE="$WORKDIR/resolve-failures.tsv"
CANDIDATES_FILE="$WORKDIR/live-candidates.tsv"

if ! http_get "$EPISODE_URL" > "$WORKDIR/connectivity.html" 2>/dev/null; then
    printf 'Integración en vivo omitida: AnimeAV1 no es accesible.\n' >&2
    exit 77
fi

av1_resolve_video_candidates "$EPISODE_URL" > "$CANDIDATES_FILE" || true
while IFS=$'\t' read -r server url referer origin media_type; do
    [[ -n "$url" ]] || continue
    if probe_media_url "$url" "$referer" "$origin" "$media_type"; then
        printf 'Integración en vivo: OK (%s/%s, HTTP %s, %s)\n' \
            "$LANGUAGE" "$server" "$PROBE_HTTP_STATUS" "$PROBE_CONTENT_TYPE"
        exit 0
    fi
    printf '%s\t%s\n' "$server" "$PROBE_REASON" >> "$RESOLVE_FAILURES_FILE"
done < "$CANDIDATES_FILE"

status=$(cat "$RESOLVE_STATUS_FILE" 2>/dev/null || printf 'NO_RESOLVED')
if [[ "$status" == NO_VARIANT ]]; then
    printf 'Integración en vivo: la variante %s no existe en %s.\n' "$LANGUAGE" "$EPISODE_URL" >&2
else
    printf 'Integración en vivo: ninguna fuente pasó el probe (%s).\n' "$status" >&2
fi
if [[ -s "$RESOLVE_FAILURES_FILE" ]]; then
    awk -F '\t' '!seen[$0]++ {printf "- %s: %s\n", $1, $2}' "$RESOLVE_FAILURES_FILE" >&2
fi
exit 1
