# ani-es-animeav1

Cliente de terminal para buscar y reproducir anime con `mpv`. Usa AnimeAV1 como proveedor principal y conserva JKAnime como respaldo.

Este proyecto es una distribución independiente basada en [Zhuchii/ani-es](https://github.com/Zhuchii/ani-es). No está afiliado con AnimeAV1, JKAnime ni los servidores de video que aparecen en sus páginas.

## Características

- DUB como idioma predeterminado; `--sub` selecciona subtítulos.
- Separación real de enlaces SUB/DUB.
- Probes HTTP antes de abrir `mpv`: nunca acepta HTML, JSON, JavaScript o CSS como video.
- Fallback automático entre HLS/Zilla, PixelDrain, MP4Upload y otros candidatos.
- Diagnósticos para variante ausente, servidor no disponible y stream inválido.
- Historial separado por proveedor e idioma.
- Instalación sin privilegios en `~/.local/bin`.
- Temporales privados y limpieza automática.
- Pruebas unitarias sin Internet e integración en vivo opcional.

## Plataformas y requisitos

Se admite:

- Linux con Bash 4 o posterior.
- WSL con Bash 4 o posterior y un reproductor funcional.
- macOS con una versión moderna de Bash instalada mediante Homebrew u otro gestor.

Dependencias requeridas:

```text
bash >= 4, curl, fzf, grep, sed, awk, sort, jq, python3, mpv y utilidades estándar del sistema
```

Dependencias opcionales recomendadas:

```text
yt-dlp, ffmpeg
```

El instalador comprueba las dependencias, incluido el reproductor indicado por `ANI_ES_PLAYER`, pero nunca ejecuta el gestor de paquetes ni usa `sudo`. Ejemplos de instalación manual:

```bash
# Debian/Ubuntu
sudo apt install bash curl fzf grep sed gawk jq python3 mpv yt-dlp ffmpeg

# Fedora
sudo dnf install bash curl fzf grep sed gawk jq python3 mpv yt-dlp ffmpeg

# Arch Linux
sudo pacman -S --needed bash curl fzf grep sed gawk jq python mpv yt-dlp ffmpeg

# macOS/Homebrew
brew install bash curl fzf jq python mpv yt-dlp ffmpeg
```

## Instalación

Descarga o clona el repositorio y ejecuta:

```bash
cd ani-es-animeav1
./tests/run-tests.sh
./install.sh
```

El instalador copia únicamente `ani-es` a `${ANI_ES_INSTALL_DIR:-$HOME/.local/bin}` mediante un reemplazo atómico. No modifica archivos de configuración de la shell.
También se niega a sobrescribir un ejecutable ajeno o un enlace simbólico con el mismo nombre.

Si el directorio no está en `PATH`, añade esta línea al archivo de inicio de tu shell:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

También se puede ejecutar sin instalar:

```bash
./ani-es "frieren"
```

Para desinstalar el ejecutable y conservar el historial:

```bash
./uninstall.sh
```

`./uninstall.sh --purge` retira únicamente el historial conocido; cualquier otro archivo que comparta el directorio se conserva.

## Uso

```bash
ani-es "chainsaw man"             # DUB predeterminado
ani-es --sub "chainsaw man"       # SUB explícito
ani-es --continue "one piece"
ani-es --server hls "frieren"
ani-es --server mp4upload "frieren"
ani-es --provider jkanime "naruto"
```

Opciones:

```text
-c, --continue
-p, --provider animeav1|jkanime
    --sub
    --dub
    --server auto|hls|pdrain|upnshare|mp4upload|mega
    --debug
    --keep-workdir
-u, --update
-v, --version
-h, --help
```

Variables configurables:

```text
ANI_ES_PROVIDER
ANI_ES_SERVER
ANI_ES_STATE_DIR
ANI_ES_PLAYER
ANI_ES_PLAYER_FLAGS
ANI_ES_HTTP_TIMEOUT
ANI_ES_USER_AGENT
ANI_ES_DEBUG
ANI_ES_KEEP_WORKDIR
```

Cada búsqueda comienza en DUB de forma deliberada. Usa `--sub` cuando el doblaje no exista.

## Actualizaciones verificadas

`--update` está deshabilitado hasta proporcionar tanto la URL HTTPS como el SHA-256 publicado del ejecutable independiente. No uses para ello el `.tar.gz`:

```bash
ANI_ES_UPDATE_URL="https://github.com/ORGANIZACION/REPOSITORIO/releases/download/v2.0.0/ani-es-2.0.0" \
ANI_ES_UPDATE_SHA256="SHA256_PUBLICADO_EN_ani-es-2.0.0.sha256" \
ani-es --update
```

Sustituye la organización, el repositorio, la versión y el SHA-256 por los valores de la versión publicada que quieras instalar.

La actualización se rechaza si el checksum, la cabecera o la sintaxis Bash no coinciden. Para máxima reproducibilidad se recomienda instalar desde una versión etiquetada y verificar los archivos de `dist/`.

Quien mantenga el proyecto puede crear y comprobar el paquete reproducible con:

```bash
make release
make verify-release
```

El release genera cuatro archivos: el paquete `ani-es-animeav1-VERSION.tar.gz`, su checksum, el ejecutable actualizable `ani-es-VERSION` y su checksum.

## Estado, privacidad y depuración

El historial se guarda en:

```text
${ANI_ES_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/ani-es}/history.json
```

No se guardan credenciales. Las queries y fragmentos de URL se redactan en el diagnóstico. Para conservar temporalmente HTML, payloads, probes y salida de `mpv`:

```bash
ANI_ES_DEBUG=1 ANI_ES_KEEP_WORKDIR=1 ani-es "frieren"
```

Revisa y elimina el `WORKDIR` mostrado cuando termines.

## Pruebas

```bash
make test
make audit
```

La suite normal usa un servidor HTTP local y no depende de AnimeAV1. La integración en vivo es voluntaria:

```bash
./tests/integration-live.sh
ANI_ES_LIVE_LANGUAGE=dub ANI_ES_LIVE_SERVER=mp4upload ./tests/integration-live.sh
```

## Limitaciones

- Los sitios y hosts externos pueden cambiar o dejar de estar disponibles.
- UPNShare y Mega pueden requerir JavaScript o clientes específicos; `auto` intenta otros servidores.
- La ficha general de AnimeAV1 no siempre declara variantes por episodio; se comprueban al elegirlo.
- Algunas películas usan internamente el episodio `0`; el selector muestra `1` y conserva la URL real.

El proyecto no aloja, redistribuye ni controla contenido multimedia. Quien lo use debe cumplir las leyes y términos aplicables en su jurisdicción.

## Contribuir y seguridad

Consulta [CONTRIBUTING.md](CONTRIBUTING.md), [SECURITY.md](SECURITY.md) y [SUPPORT.md](SUPPORT.md).

## Créditos y licencia

Basado en `ani-es`, creado por Zhuchii. Distribuido bajo la licencia MIT incluida en [LICENSE](LICENSE); consulta también [NOTICE](NOTICE).
