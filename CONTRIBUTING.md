# Contribuir

Gracias por contribuir a `ani-es-animeav1`.

## Preparación

1. Usa Bash 4 o posterior.
2. Instala las dependencias indicadas en el README.
3. Crea una rama desde `main`.
4. Mantén los cambios pequeños y enfocados.

## Validación requerida

```bash
make test
make audit
```

La suite normal no debe depender de Internet. Cuando un cambio refleje HTML real, añade una fixture mínima y anonimizada. No incluyas:

- cookies, tokens o URLs firmadas vigentes;
- rutas personales o nombres de usuario locales;
- historiales de reproducción;
- páginas HTML completas si basta un fragmento estructural;
- contenido multimedia con copyright.

La integración en vivo es opcional y debe hacer pocas peticiones:

```bash
./tests/integration-live.sh
```

## Estilo

- Conserva Bash y Python estándar; evita dependencias pesadas.
- Usa `mktemp` para temporales y valida cualquier borrado recursivo.
- No ejecutes JavaScript remoto ni uses `eval` con contenido descargado.
- No consideres éxito únicamente el código de salida de un host o reproductor.
- Documenta cambios públicos en `CHANGELOG.md`.

## Pull requests

Describe la causa, el cambio, las pruebas y las limitaciones. Las correcciones de scraping deben indicar qué estructura externa cambió sin publicar datos sensibles.
