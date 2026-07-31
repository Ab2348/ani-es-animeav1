# Relación con el proyecto original

`ani-es-animeav1` deriva de [Zhuchii/ani-es](https://github.com/Zhuchii/ani-es) y conserva su licencia MIT.

La distribución independiente existe porque incorpora cambios arquitectónicos amplios: proveedores, AnimeAV1, separación SUB/DUB, probes, historial XDG, instalación sin privilegios y pruebas automatizadas.

Las mejoras que puedan beneficiar al proyecto original deberían proponerse en PR pequeños y autocontenidos:

1. temporales privados y limpieza segura;
2. instalación sin permisos globales;
3. probes y fallback de reproducción;
4. interfaz de proveedores;
5. proveedor AnimeAV1 y sus fixtures.

No debe presentarse el árbol completo como un parche pequeño ni asumirse compatibilidad directa entre los historiales de ambos proyectos.

## Notas técnicas de AnimeAV1

- SvelteKit puede serializar valores ausentes como `void 0`.
- Los enlaces suelen residir en `embeds` y `downloads`, separados por `DUB` y `SUB`.
- La ficha general no siempre declara las variantes disponibles de cada episodio.
- Zilla usa `/m3u8/<id>`, pero el manifiesto debe validarse antes de abrir el reproductor.
- Algunas películas se publican como episodio `0`.
