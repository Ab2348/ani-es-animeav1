# Publicar una versión

## Preparación

1. Actualiza `VERSION` en `ani-es` y `CHANGELOG.md`.
2. Verifica que el árbol esté limpio.
3. Ejecuta:

```bash
make test
make audit
make release
make verify-release
```

4. Confirma que dos ejecuciones de `make release` producen los mismos SHA-256.
5. Crea un tag firmado o anotado `vX.Y.Z` sobre el commit validado.
6. Publica los cuatro archivos generados en `dist/`: el `.tar.gz`, el ejecutable `ani-es-X.Y.Z` y ambos `.sha256`.

## Reglas

- Nunca construyas una versión desde archivos sin commit.
- No publiques el historial local de reproducción ni artefactos de integración.
- No apuntes actualizaciones automáticas a `main`; usa un artefacto de una versión etiquetada.
- Copia el SHA-256 exactamente como aparece en el archivo de checksum.
- Usa el checksum de `ani-es-X.Y.Z` para `ANI_ES_UPDATE_SHA256`; el checksum del `.tar.gz` no es intercambiable.
