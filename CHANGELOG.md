# Historial de cambios

Este proyecto sigue [Versionado Semántico](https://semver.org/lang/es/).

## [2.0.0] - 2026-07-31

Primera versión pública independiente de `ani-es-animeav1`.

- AnimeAV1 como proveedor predeterminado y JKAnime como respaldo.
- DUB predeterminado con selección SUB explícita.
- Extracción de payloads SvelteKit, incluidos `void 0`, `embeds` y `downloads`.
- Resolución separada por idioma y servidor.
- Probes limitados para HLS y archivos directos antes de ejecutar `mpv`.
- Fallback automático y diagnóstico detallado de fallos.
- Soporte para películas publicadas como episodio `0`.
- Historial atómico bajo XDG y migración de formatos anteriores.
- Instalación sin `sudo`, actualización con SHA-256 obligatorio y desinstalación defensiva.
- Artefacto ejecutable independiente para que `--update` pueda consumir releases verificadas.
- Pruebas locales sin Internet e integración en vivo opcional.
