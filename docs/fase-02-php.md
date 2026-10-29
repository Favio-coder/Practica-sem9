# Fase 02 — Implementación PHP

## Objetivo y alcance

Registrar contactos de la **Biblioteca UNCP – FIS**, Facultad de Ingeniería de Sistemas, mediante nombre y correo. Solo hay almacenamiento temporal por sesión PHP; JSP no se implementa en esta fase.

## Archivos

- `php-app/index.html`: formulario POST accesible con teclado, etiquetas y atributos de longitud máxima.
- `php-app/registro.php`: respuestas HTTP, validación, sesión y tabla.
- `php-app/styles.css`: diseño adaptable, contraste y foco visible.
- `php-app/assets/img/Fis.png` y `jsp-app/assets/img/Fis.png`: imagen institucional PNG de 150 × 150 trasladada desde los archivos preexistentes `assets/Fis.png` de cada proyecto, sin modificar sus bytes (SHA-256 de ambas: `9a5db561bbbe4b7cd1335a431632841f9030f61f3c2d91023f0b1be6b710cbd2`). **No hace falta colocarla manualmente.** Las páginas PHP la referencian con `assets/img/Fis.png`, texto alternativo y ancho adaptable.
- `docs/fase-02-php.md`, `README.md`, `docs/fases.md`, `docs/contrato-funcional.md`: avance y política de validación.

## Recorrido HTTP

`index.html` envía `nombre` y `correo` por POST a `registro.php`. Antes de imprimir HTML, PHP configura UTF-8 y comprueba el método: cualquier método diferente de POST recibe **405** con `Allow: POST` y no modifica la sesión. `filter_input(INPUT_POST, ...)` rechaza campos ausentes y arrays; después se aplica `trim()`, se comprueba UTF-8, longitud y correo mediante `FILTER_VALIDATE_EMAIL`. Un error produce **400** con mensaje y enlace, sin abrir ni modificar la sesión. Se rechazan controles en el nombre (por ejemplo, saltos de línea y NUL). La política definida para la posterior comparación JSP es: nombre de **1 a 100 caracteres UTF-8** tras `trim()`, sin controles, y correo no vacío, hasta **254 caracteres UTF-8** tras `trim()`, válido como dirección electrónica. Los atributos `required` y `maxlength` del formulario solo ayudan al usuario: manda la validación del servidor.

Con datos válidos se abre o recupera la sesión; `$_SESSION['registros']` almacena los valores validados **sin preescapar**. El registro se añade y se responde **200** con numeración y tabla de los contactos de esa sesión. Al construir cada celda se usa `htmlspecialchars(..., ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8')` para impedir que el contenido se interprete como HTML. Las respuestas no incluyen detalles internos de fallos de sesión. En HTTP local se mantienen las cookies de sesión con la configuración de PHP, sin forzar el atributo `Secure`.

## Entorno y despliegue

Antes de probar se comprobó `php --version` (8.3.6), `php -m` (`filter`, `mbstring`, `session`), `php -l php-app/registro.php` (sin errores), `apache2ctl -M` (`php_module`), `apache2ctl -S` (sitio `*:80`, DocumentRoot `/var/www/html`), `systemctl is-active apache2.service` (`active`) y `curl http://localhost:80/` (200). Un GET a `http://localhost:80/lab09-php/procesar.php` devolvió contenido producido por el PHP previo: confirma ejecución HTTP de PHP en el Apache del puerto 80, **no** verifica el nuevo código ni altera esa aplicación. `/var/www/html` y `/var/www/html/lab09-php` son de `root:root`; `sudo -n true` devolvió «se requiere una contraseña». No se publicaron archivos nuevos en ese DocumentRoot.

**Publicación pendiente (en terminal local con permisos de administración):** desde la raíz del repositorio, comprobar primero los prerrequisitos anteriores y que `/var/www/html/lab09-contactos-php` no pertenece a otra aplicación. Crear solo ese directorio nuevo; por ejemplo:

```bash
php -l php-app/registro.php
apache2ctl -M   # debe aparecer php_module
apache2ctl -S   # debe mostrar /var/www/html para :80
test ! -e /var/www/html/lab09-contactos-php
sudo install -d -m 755 /var/www/html/lab09-contactos-php/assets/img
sudo install -m 644 php-app/index.html php-app/registro.php php-app/styles.css /var/www/html/lab09-contactos-php/
sudo install -m 644 php-app/assets/img/Fis.png /var/www/html/lab09-contactos-php/assets/img/Fis.png
curl --noproxy '*' -sS -o /dev/null -w '%{http_code}\n' http://localhost:80/lab09-contactos-php/index.html
```

La URL permanente prevista es **`http://localhost:80/lab09-contactos-php/index.html`**, **aún sin verificar**. Una vez publicado, repetir las pruebas HTTP siguientes contra esa URL; no modificar ni sustituir `/var/www/html/lab09-php`. Si falta integración PHP, habilitar el módulo PHP 8.3 para Apache con autorización local (`sudo apt install libapache2-mod-php8.3`, `sudo a2enmod php8.3`, `sudo systemctl restart apache2`), volver a comprobar `apache2ctl -M` y un POST HTTP; no usar el servidor integrado de PHP como reemplazo. Aquí el módulo ya está presente y el bloqueo efectivo es el permiso de publicación.

**URL verificada para este código:** `http://127.0.0.1:18080/index.html` respondió 200 en una instancia **temporal y aislada de Apache 2.4 con el mismo módulo libphp8.3**, cuyo DocumentRoot apunta directamente a `php-app/`. Es un puerto de ensayo, no el sitio permanente del puerto 80; puede dejar de responder al cerrar esta instancia o reiniciar el equipo. La ejecución PHP y los resultados de abajo corresponden a `http://127.0.0.1:18080/`.

## Pruebas ejecutadas

El 2026-10-29 se inició la instancia temporal de Apache y se enviaron peticiones con `curl` a la URL verificada. Para las sesiones se usaron **dos archivos temporales distintos de cookies** (sin imprimir ni conservar los identificadores); los cuerpos y cookies de ensayo se eliminaron al terminar. Ejemplo reproducible mientras la instancia de ensayo esté activa (usar la URL permanente cuando esté publicada):

```bash
base=http://127.0.0.1:18080
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl --noproxy '*' -sS -o "$tmp/form.html" -w '%{http_code}\n' "$base/index.html"
curl --noproxy '*' -sS -b "$tmp/sesion1" -c "$tmp/sesion1" \
  --data-urlencode 'nombre=Ana Torres' --data-urlencode 'correo=ana@example.org' \
  -o "$tmp/uno.html" -w '%{http_code}\n' "$base/registro.php"
curl --noproxy '*' -sS -b "$tmp/sesion1" -c "$tmp/sesion1" \
  --data-urlencode 'nombre=Luis Pérez' --data-urlencode 'correo=luis@example.org' \
  -o "$tmp/dos.html" -w '%{http_code}\n' "$base/registro.php"
curl --noproxy '*' -sS -b "$tmp/sesion2" -c "$tmp/sesion2" \
  --data-urlencode 'nombre=Eva Sol' --data-urlencode 'correo=eva@example.org' \
  -o "$tmp/nueva.html" -w '%{http_code}\n' "$base/registro.php"
curl --noproxy '*' -sS -o /dev/null -w '%{http_code} %header{allow}\n' "$base/registro.php"
curl --noproxy '*' -sS --data-urlencode 'nombre=   ' \
  --data-urlencode 'correo=ana@example.org' -o /dev/null -w '%{http_code}\n' "$base/registro.php"
curl --noproxy '*' -sS -o /dev/null -w '%{http_code} %{content_type}\n' "$base/assets/img/Fis.png"
# Casos de rechazo y método (no se envían cookies de las sesiones válidas):
curl --noproxy '*' -sS --data-urlencode 'nombre=' --data-urlencode 'correo=ana@example.org' -o /dev/null -w '%{http_code}\n' "$base/registro.php"
curl --noproxy '*' -sS --data-urlencode 'nombre=Ana' --data-urlencode 'correo=invalido' -o /dev/null -w '%{http_code}\n' "$base/registro.php"
curl --noproxy '*' -sS -X POST -o /dev/null -w '%{http_code}\n' "$base/registro.php"
curl --noproxy '*' -sS --data-urlencode 'nombre[]=Ana' --data-urlencode 'correo=ana@example.org' -o /dev/null -w '%{http_code}\n' "$base/registro.php"
curl --noproxy '*' -sS --data-urlencode 'nombre=Ana' --data-urlencode 'correo[]=ana@example.org' -o /dev/null -w '%{http_code}\n' "$base/registro.php"
curl --noproxy '*' -sS -X PUT -o /dev/null -w '%{http_code} %header{allow}\n' "$base/registro.php"
curl --noproxy '*' -sS -b "$tmp/sesion1" -c "$tmp/sesion1" --data-urlencode 'nombre=<script>alert(1)</script>' --data-urlencode 'correo=html@example.org' -o "$tmp/html.html" -w '%{http_code}\n' "$base/registro.php"
```

Se comprobó el contenido de las respuestas en las pruebas, no únicamente el estado HTTP:

| Caso ejecutado | Resultado real |
| --- | --- |
| `php -l php-app/registro.php` | Sin errores de sintaxis |
| GET `index.html` | 200, formulario POST e imagen con ruta relativa |
| GET `assets/img/Fis.png` | 200, `image/png`, mismos bytes que el archivo fuente |
| POST válido con primera cookie | 200, Ana y su correo visibles |
| Segundo POST con la misma cookie | 200, Ana y Luis presentes; fila n.º 2 |
| POST con cookie nueva | 200, Eva presente; Ana y Luis ausentes |
| Nombre vacío y nombre de solo espacios | 400 en ambos casos, mensaje y enlace |
| Correo inválido | 400 |
| Ambos campos ausentes; `nombre[]`; `correo[]` | 400 en los tres casos, sin advertencias ni errores internos |
| Nombre de 101 caracteres | 400 |
| GET y PUT a `registro.php` | 405 y cabecera `Allow: POST` en ambos |
| Nombre `<script>alert(1)</script>` | 200, aparece `&lt;script&gt;...&lt;/script&gt;` en HTML; no aparece la etiqueta ejecutable |
| POST válido tras los inválidos en la misma sesión | 200, solo cuatro registros válidos; los rechazados no se agregaron |

**Fallidas:** ninguna en las pruebas ejecutadas. **Pendientes:** repetir estas pruebas en el despliegue permanente sobre el puerto 80, revisión visual en navegador (no disponible en esta ejecución), verificar manualmente ancho móvil, contraste y foco con Tab, y obtener capturas. La prueba de 500 controlado pertenece a la fase de QA. Continúan las comprobaciones privilegiadas de `docs/entorno.md` y la consulta al docente sobre Apache nativo.

Guardar manualmente en `docs/evidencias/` (sin copiar identificadores de sesión):

1. `fase02-01-formulario-php.png`: formulario con logo, título y campos visibles.
2. `fase02-02-registros-php.png`: tabla con dos contactos en la misma sesión.
3. `fase02-03-validacion-php.png`: mensaje de entrada inválida y enlace de regreso.
4. `fase02-04-http-405-php.png`: respuesta 405 y cabecera `Allow: POST` en las herramientas de red o terminal, ocultando cookies si aparecen.

No se generaron capturas en esta fase.
