# Arquitectura

## Flujo principal

```text
búsqueda → selección de anime → metadatos → selección de episodio
→ extracción SUB/DUB → resolución por servidor → probe → mpv → historial
```

## Proveedores

Las funciones `provider_*` aíslan búsqueda, metadatos, URL de episodio y candidatos de reproducción. AnimeAV1 es el proveedor predeterminado; JKAnime se conserva como respaldo.

## Fuentes multimedia

Los parsers producen filas tabuladas con idioma, tipo, servidor, URL y calidad. Los resolutores convierten embeds conocidos en URL HLS o archivo, junto con `Referer`, `Origin` y tipo de medio.

Antes de ejecutar `mpv`:

- HLS debe responder 200/206 y contener `#EXTM3U`;
- un archivo debe responder 200/206 y declarar un tipo multimedia o una firma reconocible;
- cada probe solicita como máximo un rango pequeño y aplica un límite de descarga.

## Estado

El historial es JSON y se reemplaza de forma atómica. La clave combina proveedor, idioma y URL del anime. Los temporales viven en un directorio exclusivo creado con `mktemp -d`.

## Límites de confianza

AnimeAV1, JKAnime, embeds y streams son entradas no confiables. El programa analiza datos, pero no evalúa JavaScript remoto. `mpv` recibe únicamente candidatos que hayan pasado un probe compatible.
