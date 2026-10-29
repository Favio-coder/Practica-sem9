# Fase 4 — QA y seguridad conjunta

**Fecha:** 2026-10-29. Comprobaciones en el equipo accesible por las herramientas; no se acredita que sea la laptop personal del autor. Fuentes revisadas: `php-app/`, `jsp-app/` y documentación de fases 1–3. Se conservaron logo y temática Biblioteca UNCP – FIS. No se reiniciaron los servicios principales.

## Entornos y alcance de los resultados

| Implementación probada | URL que ejecuta este código | Servicio principal correspondiente |
| --- | --- | --- |
| PHP con módulo Apache 8.3 | `http://127.0.0.1:18080/index.html` → 200 | `http://localhost:80/lab09-contactos-php/index.html` → **404**, no publicado |
| JSP con Tomcat 10.1.55 | `http://127.0.0.1:18081/biblioteca-fis/index.jsp` → 200 | `http://localhost:8080/biblioteca-fis/index.jsp` → **404**, no publicado |

Los puertos 18080 y 18081 son instalaciones **aisladas/temporales** del mismo equipo accesible. Su disponibilidad depende de esos procesos; las pruebas aprobadas aquí **no** equivalen a aprobar el despliegue en los puertos permanentes. `/var/www/html/lab09-php/` y `/var/lib/tomcat10/webapps/lab09-jsp/` son aplicaciones preexistentes, no las nuevas. La lectura de `appBase` del Tomcat principal y la instalación en rutas protegidas siguen requiriendo permisos (`docs/fase-02-php.md` y `docs/fase-03-jsp.md`).

## Matriz ejecutada

Se usó `curl` con dos archivos temporales de cookies por plataforma, inspeccionando respuestas, cabeceras y contenido; los archivos temporales se eliminaron. Datos de ensayo: Ana, Luis, Eva y correos `example.org`. **A = aprobado, F = fallido, NE = no ejecutado**; el estado PHP/JSP refleja solo los entornos de ensayo indicados.

| Caso | Esperado | Observado PHP :18080 | Observado JSP :18081 | Estado PHP/JSP |
| --- | --- | --- | --- | --- |
| 1. Formulario | 200, identidad, POST y campos | 200, `action="registro.php"`, logo y campos | 200, `action="registro.jsp"`, logo y campos | A / A |
| 2. POST válido | 200, contacto en tabla | 200, Ana y correo, fila 1 | 200, Ana y correo, fila 1 | A / A |
| 3. Segundo POST, misma cookie | Ambos presentes | 200, Ana y Luis, fila 2 | 200, Ana y Luis, fila 2 | A / A |
| 4. Cookie nueva | Solo contactos propios | 200, solo Eva | 200, solo Eva | A / A |
| 5. Nombre vacío o espacios | 400, mensaje y enlace | 400 en ambos; sin traza | 400 en ambos; sin traza | A / A |
| 6. Correo inválido | 400 | 400 y mensaje | 400 y mensaje | A / A |
| 7. Campos ausentes | 400 | 400 y mensaje | 400 y mensaje | A / A |
| 8. Forma inesperada | Rechazo controlado, sin 500 | `nombre[]`, `correo[]` y `nombre` seguido de `nombre[]`: 400 | Los mismos: 400 | A / A |
| 9. Límites | Nombre de 100 caracteres aceptado; 101 y correo de 255 rechazados | 200 para 100 `ñ`; 400 para 101 y 255 | 200 para 100 `ñ`; 400 para 101 y 255 | A / A |
| 10. GET al registro | 405 y `Allow: POST` | 405, cabecera y enlace | 405, cabecera y enlace | A / A |
| 11. Nombre con HTML/XSS | Escapar cinco caracteres; no ejecutar script | 200; entidades `&lt;`, `&gt;`, `&amp;`, `&quot;`, `&#039;`; navegador sin alerta | 200; mismas entidades (`&#39;` para `'`); navegador sin alerta | A / A |
| 12. Tildes, ñ y `&` | UTF-8 correcto; `&` escapado | 200; `María Peña Ñúñez &amp; Sol` | 200; igual | A / A |
| 13. POST inválidos no suman | Solo seis válidos previos en sesión | Siguiente POST 200, fila 6 sí, fila 7 no | Igual | A / A |
| 14. CSS y logo | 200, MIME y bytes esperados | 200 `text/css` e `image/png`, bytes iguales a fuentes | Igual | A / A |
| 15. Ruta inexistente | 404 | 404 | 404 | A / A |
| 16. Logs de pruebas válidas | Sin errores nuevos de Apache o compilación JSP | Log de ensayo solo dos avisos de arranque previos; sin errores nuevos | Sin error nuevo por POST válidos ni `JasperException`; `.java`/`.class` de ambas JSP generados en `work/Catalina/localhost/biblioteca-fis/` | A / A |
| Parámetro escalar duplicado | Rechazo consistente para el formulario normal | **Antes:** 200, se guardaba último `Dos`. **Después de corrección:** 400; siguiente POST confirma que no se sumó | 400 por `getParameterValues()`; no se suma | A / A tras corrección |
| 500 controlado, fuera de apps normales | 500 genérico sin traza ni caída de servicios | 500 por ruta de sesiones no disponible en **Apache aislado :18082**; mensaje genérico; instancia detenida | 500 por atributo de sesión de tipo inesperado en contexto temporal **`/qa04-500`** del Tomcat aislado; mensaje genérico; contexto retirado | A / A (solo ensayo) |
| Publicación nueva en servicios principales | Formulario 200 en :80/:8080 tras desplegar | 404: despliegue pendiente | 404: despliegue pendiente | F / F (disponibilidad); pruebas funcionales allí NE / NE |

**Resultado automatizado final:** 46 aserciones HTTP aprobadas y 0 fallidas **en los servidores de ensayo**, además de las dos pruebas 500 aisladas y la inspección visual; hubo dos fallos **del comprobador** en su primer recorrido (contaba mal los registros válidos tras la prueba Unicode). Se corrigió el conteo en el comprobador temporal, no en la aplicación, y se repitió toda la matriz. **Fallida para la entrega permanente:** disponibilidad de ambas URL principales (404 porque no se publicó allí). Las pruebas funcionales sobre esos dos servicios permanecen **no ejecutadas**.

### Duplicados, política y corrección

Antes de la corrección, `nombre=Uno&nombre=Dos&correo=dos@example.org` daba **PHP 200** y almacenaba «Dos»; JSP daba **400**. PHP ya había normalizado los parámetros cuando `filter_input(INPUT_POST, ...)` los leyó: **no es posible detectar la repetición a partir del `$_POST` resultante**. Para el cuerpo `application/x-www-form-urlencoded` generado por estos formularios, `registro.php` ahora inspecciona `php://input`, decodifica los nombres de cada campo y rechaza claves duplicadas o inesperadas **antes** de leer los valores validados mediante `filter_input`. No se modificaron los límites ni los criterios para nombre/correo. Se verificó de nuevo el POST ordinario, el duplicado, `nombre[]` incluso mezclado con un escalar y el aislamiento de sesiones. `multipart/form-data` no emplea esta inspección del cuerpo: la detección de duplicados allí no está garantizada; ese formato no lo envían los formularios de la práctica. Los validadores de correo PHP (`FILTER_VALIDATE_EMAIL`) y Java (regex básica) tampoco son idénticos para todas las direcciones, como documenta la fase 3.

## Reproducción sin divulgar cookies

Desde la raíz del repositorio, mientras los servidores de ensayo estén activos:

```bash
php -l php-app/registro.php
base=http://127.0.0.1:18080  # cambiar por http://127.0.0.1:18081/biblioteca-fis para JSP
endpoint=registro.php         # usar registro.jsp para JSP
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl --noproxy '*' -sS -b "$tmp/s1" -c "$tmp/s1" --data-urlencode 'nombre=Ana Torres' --data-urlencode 'correo=ana@example.org' -o "$tmp/uno.html" -w '%{http_code}\n' "$base/$endpoint"
curl --noproxy '*' -sS -b "$tmp/s1" -c "$tmp/s1" --data-urlencode 'nombre=Luis Pérez' --data-urlencode 'correo=luis@example.org' -o "$tmp/dos.html" -w '%{http_code}\n' "$base/$endpoint"
curl --noproxy '*' -sS -b "$tmp/s2" -c "$tmp/s2" --data-urlencode 'nombre=Eva Sol' --data-urlencode 'correo=eva@example.org' -o "$tmp/otra.html" -w '%{http_code}\n' "$base/$endpoint"
curl --noproxy '*' -sS -o /dev/null -w '%{http_code} %header{allow}\n' "$base/$endpoint"
curl --noproxy '*' -sS --data-urlencode 'nombre=Uno' --data-urlencode 'nombre=Dos' --data-urlencode 'correo=dos@example.org' -o /dev/null -w '%{http_code}\n' "$base/$endpoint"
```

No imprimir `Set-Cookie`, archivos `s1`/`s2` ni logs de acceso completos. Ejemplos de **salida real filtrada**: [`docs/evidencias/fase04-http-resumen.txt`](evidencias/fase04-http-resumen.txt) y [`docs/evidencias/fase04-logs-resumen.txt`](evidencias/fase04-logs-resumen.txt). Para el filtro Java se recompiló con `javac -encoding UTF-8 -cp /usr/share/tomcat10/lib/servlet-api.jar`; las solicitudes HTTP activaron la compilación real de las JSP, no solo el estado del servicio. Los logs de ensayo se leyeron tras las pruebas; contienen una recarga fallida **anterior (fase 3, 10:08)** seguida por recarga completa y ningún error nuevo de compilación JSP imputable a los POST válidos de fase 4. Los logs del servicio principal no prueban nuestra aplicación porque no está desplegada allí.

El 500 PHP se obtuvo únicamente en otra instancia Apache :18082 con `session.save_path` apuntando a una ruta inexistente; se verificó el mensaje genérico y se detuvo esa instancia. El 500 JSP se obtuvo al reenviar un POST válido desde un JSP temporal que colocó un tipo incorrecto bajo `session.registros` en **otro contexto aislado**; se comprobó el cuerpo sin trazas y se retiró ese contexto (HTTP 404 después). No se dañaron ni reiniciaron los servicios Apache/Tomcat normales y no quedó ningún endpoint 500 en el proyecto.

## Evidencias visuales y pendientes

Se utilizó Brave/Chromium en modo sin interfaz con navegación HTTP real y envíos POST desde los formularios. Se inspeccionaron imágenes a 1280×900 y viewport móvil de 390 px: logo visible, formulario y tabla legibles, errores con texto/enlace. La carga XSS se muestra como texto en ambos resultados; se comprobó que no había etiqueta `<script>` en la página de respuesta ni se abrió alerta.

Capturas **reales** en `docs/evidencias/` (solo contactos ficticios):

- `fase04-formulario-php.png`, `fase04-tabla-php.png`, `fase04-validacion-php.png`.
- `fase04-formulario-jsp.png`, `fase04-tabla-jsp.png`, `fase04-validacion-jsp.png`.
- Vistas móviles: `fase04-formulario-movil-php.png`, `fase04-tabla-movil-php.png`, `fase04-formulario-movil-jsp.png`, `fase04-tabla-movil-jsp.png`.
- Prueba visual XSS: `fase04-xss-texto-php.png`, `fase04-xss-texto-jsp.png`.

**Pendientes/bloqueos para entregar:** confirmar `appBase` real con permisos; instalar el código PHP nuevo en el DocumentRoot :80 y el WAR JSP nuevo en el Tomcat :8080 sin tocar aplicaciones preexistentes; repetir la matriz, evidencias y revisión visual sobre esas URL permanentes. Las capturas son de los **servidores temporales**, no deben presentarse como capturas de los servicios principales. Si se sustituyen por capturas de los servicios permanentes, usar los pasos y rutas de `docs/fase-02-php.md` y `docs/fase-03-jsp.md`. No se hizo limpieza final, ZIP ni publicación GitHub.
