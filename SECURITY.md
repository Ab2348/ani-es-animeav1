# Política de seguridad

## Versiones mantenidas

La rama principal y la última versión `2.x` reciben correcciones de seguridad.

## Reportar una vulnerabilidad

Usa la opción privada **Security → Report a vulnerability** del repositorio. No publiques credenciales, cookies, URLs firmadas ni datos personales en issues.

Incluye:

- versión de `ani-es`;
- sistema operativo y versión de Bash;
- pasos mínimos para reproducir;
- impacto esperado;
- una prueba de concepto sin contenido sensible.

## Modelo de seguridad

- El programa no ejecuta JavaScript remoto.
- Los streams se prueban con descargas parciales antes de abrir `mpv`.
- HTML, JSON, JavaScript, CSS e imágenes se rechazan como fuentes multimedia.
- Los temporales se crean con permisos privados y se eliminan al salir.
- Las URLs con query o fragmento se redactan en los diagnósticos.
- Las peticiones y redirecciones se restringen a HTTP(S); las actualizaciones exigen HTTPS y un SHA-256 proporcionado explícitamente.
- El instalador no usa `sudo` ni modifica la configuración de la shell.
- El instalador no reemplaza ejecutables ajenos y la purga solo elimina archivos de historial conocidos.

Los proveedores y hosts son servicios externos no confiables. Una respuesta HTTP válida no implica que el servicio sea seguro o esté disponible permanentemente.
