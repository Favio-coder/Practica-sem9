# Fase 03 — Implementación JSP

## Objetivo y archivos

Registrar únicamente nombre y correo para **Biblioteca UNCP – FIS / Facultad de Ingeniería de Sistemas**, con tabla de contactos de la sesión JSP, separada de las sesiones PHP.

- `jsp-app/index.jsp`: formulario POST y encabezado institucional, UTF-8.
- `jsp-app/registro.jsp`: validación, códigos HTTP, sesión y resultados.
- `jsp-app/styles.css`: mismo CSS que la versión PHP, adaptable a celular y con foco visible.
- `jsp-app/assets/img/Fis.png`: logo existente desde fase 2, idéntico en bytes a `php-app/assets/img/Fis.png` (SHA-256 `9a5db561bbbe4b7cd1335a431632841f9030f61f3c2d91023f0b1be6b710cbd2`). No hace falta colocar imagen a mano.
- `jsp-app/WEB-INF/src/edu/uncp/biblioteca/MetodoPostFilter.java` y `jsp-app/WEB-INF/web.xml`: filtro Jakarta para contestar 405/`Allow: POST` cuando Jasper interceptaría métodos como PUT u OPTIONS antes de ejecutar la JSP. Se compila a `WEB-INF/classes/` **durante el empaquetado**; el `.class` generado no es código fuente entregable. `web.xml` es necesario para el mapeo limitado a `/registro.jsp`.
- Se actualizaron `README.md`, `docs/fases.md` y `docs/contrato-funcional.md`. Los archivos PHP no se modificaron.

## Flujo y escape

`index.jsp` declara UTF-8 y usa rutas relativas dentro de `/biblioteca-fis/`: POST a `registro.jsp`, CSS `styles.css` y logo `assets/img/Fis.png`. Antes de leer parámetros o emitir HTML, `registro.jsp` establece UTF-8 del request, comprueba el método y consulta `getParameter()` y `getParameterValues()`; también rechaza claves adicionales (por ejemplo, `nombre[]`) y dos valores para una misma clave. Un error responde **400** con mensaje y enlace sin añadir datos a `session`. El filtro responde **405** y `Allow: POST` para todo método distinto de POST, antes de que Jasper ejecute o bloquee la página; la JSP comprueba también el método como defensa propia.

En un POST válido, el objeto implícito `session` conserva una `List<Map<String, String>>` bajo `registros`. Se sincronizan la inicialización y las modificaciones de la sesión y de la lista; la tabla se construye con una copia tomada bajo el mismo bloqueo, evitando perder contactos o iterar mientras otra solicitud modifica la lista. Se guardan valores validados **sin preescaparlos**. Al imprimir nombre y correo, `escapar()` de `registro.jsp` reemplaza `&`, `<`, `>`, `"` y `'` por entidades HTML; no se usa EL sin escape. El resultado es **200** con numeración y enlace para volver. Una excepción de aplicación capturada produce 500 genérico sin traza en la página; la comprobación controlada de 500 pertenece a fase 4.

Tomcat/Jasper traduce cada JSP a un servlet Java y lo compila cuando se solicita por primera vez o cambia el archivo. En el Tomcat aislado se comprobaron los artefactos generados `work/Catalina/localhost/biblioteca-fis/org/apache/jsp/{index_jsp,registro_jsp}.{java,class}` **y** las respuestas HTTP 200/400/405; un Tomcat activo sin GET/POST satisfactorios no bastaría para probar la compilación.

## Política de validación y diferencia con PHP

Se recortan los caracteres exteriores que elimina `trim()` en el PHP de fase 2: espacio, tabulador, salto de línea, retorno, tabulación vertical y NUL. El nombre debe tener entre **1 y 100 puntos de código Unicode** y no contener controles U+0000–U+001F ni U+007F; el correo debe ser no vacío, de **hasta 254 puntos de código**, y coincidir con una expresión regular básica de dirección ASCII con local y dominio. El formulario `required`, `type="email"` y `maxlength` solo ayudan en el navegador. `getParameterValues()` rechaza duplicados incluso si `getParameter()` devolvería el primero.

PHP valida el correo con `FILTER_VALIDATE_EMAIL`; Java usa una expresión regular deliberadamente básica, sin JSTL ni biblioteca nueva. **No son validadores equivalentes en todos los casos.** Por ejemplo, se comprobó que `php -r 'var_export(filter_var("\"a.b\"@example.org", FILTER_VALIDATE_EMAIL));'` acepta `"a.b"@example.org`, mientras que un POST con ese correo al JSP de ensayo devolvió 400. Los ejemplos ordinarios `ana@example.org` y `invalido` se comportaron igual en las pruebas. PHP comprueba bytes UTF-8 antes de validar; Tomcat decodifica los parámetros, por lo que secuencias mal formadas pueden manejarse de otra manera (incluso llegar como el carácter de reemplazo U+FFFD). JSP rechaza sustitutos aislados en el nombre; no se afirma equivalencia absoluta para entradas malformadas.

## Entorno, contexto y despliegue

El servicio **principal** identificado por `systemctl show tomcat10.service` usa Tomcat **10.1.55**, Java 21, `CATALINA_HOME=/usr/share/tomcat10`, `CATALINA_BASE=/var/lib/tomcat10` y el puerto **8080**. `curl http://localhost:8080/lab09-jsp/index.jsp` respondió 200: funciona la aplicación JSP anterior. Los logs del servicio muestran el despliegue de `/var/lib/tomcat10/webapps/lab09-jsp`, pero el archivo `/etc/tomcat10/server.xml` tiene permisos `root:tomcat` y este usuario no puede leer el valor **literal** de `<Host appBase>` (`sudo -n true`: «se requiere una contraseña»). `/var/lib/tomcat10/webapps` es `tomcat:tomcat` y el usuario actual no tiene permiso de escritura. No se ha publicado la aplicación nueva en el servicio del puerto 8080: `http://localhost:8080/biblioteca-fis/index.jsp` respondió **404**. No se tocó `ROOT` ni `lab09-jsp` y no se reinició el servicio.

**Verificación funcional de esta fase:** en una instancia **aislada** del mismo Tomcat 10.1.55 con `CATALINA_BASE=/tmp/opencode/tomcat-fis`, `Host appBase="webapps"` configurado explícitamente y conector limitado a `127.0.0.1:18081`, se copió el contenido de `jsp-app/` a `webapps/biblioteca-fis/`, se compiló el filtro contra `/usr/share/tomcat10/lib/servlet-api.jar` y se atendió la URL **realmente verificada** `http://127.0.0.1:18081/biblioteca-fis/index.jsp` (HTTP 200). Esta instancia es temporal, no sustituye el despliegue pendiente en el Tomcat principal ni implica que el `appBase` de este último sea igual. La fuente se mantiene en `jsp-app/`; la copia de ensayo está fuera del repositorio.

**Primera publicación pendiente, desde la raíz del proyecto y con credenciales locales:** verificar primero el valor real de `appBase` y el conector. Continuar **solo si** `appBase="webapps"` respecto de `/var/lib/tomcat10` (o apunta explícitamente a `/var/lib/tomcat10/webapps`) y el destino no pertenece a otra app. Si difiere, sustituir en los comandos de instalación la ruta por el `appBase` confirmado. Compilar **antes** de instalar para evitar un despliegue incompleto; el WAR crea el contexto `/biblioteca-fis` automáticamente sin reiniciar Tomcat si `autoDeploy` está activo.

```bash
sudo grep -nE '<Host|appBase=|<Connector|autoDeploy=' /etc/tomcat10/server.xml
test ! -e /var/lib/tomcat10/webapps/biblioteca-fis
test ! -e /var/lib/tomcat10/webapps/biblioteca-fis.war
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
mkdir -p "$stage/app/WEB-INF/classes"
cp -a jsp-app/. "$stage/app/"
javac -encoding UTF-8 -cp /usr/share/tomcat10/lib/servlet-api.jar \
  -d "$stage/app/WEB-INF/classes" jsp-app/WEB-INF/src/edu/uncp/biblioteca/MetodoPostFilter.java
jar --create --file "$stage/biblioteca-fis.war" -C "$stage/app" .
jar tf "$stage/biblioteca-fis.war"   # comprobar WEB-INF/classes/.../MetodoPostFilter.class
sudo install -m 644 "$stage/biblioteca-fis.war" /var/lib/tomcat10/webapps/biblioteca-fis.war
curl --noproxy '*' -sS -o /dev/null -w '%{http_code}\n' http://localhost:8080/biblioteca-fis/index.jsp
```

Para **actualizar la propia aplicación** cuando ya exista, reconstruir el WAR desde `jsp-app/` con las mismas instrucciones de `stage`, `cp`, `javac` y `jar`; comprobar que `biblioteca-fis.war` sea efectivamente esta app. Reemplazar solo ese WAR mediante un nombre temporal y renombrado atómico (evita que Tomcat lea un WAR a medio escribir):

```bash
sudo install -m 644 "$stage/biblioteca-fis.war" /var/lib/tomcat10/webapps/biblioteca-fis.war.nuevo
sudo mv /var/lib/tomcat10/webapps/biblioteca-fis.war.nuevo /var/lib/tomcat10/webapps/biblioteca-fis.war
curl --noproxy '*' -sS -o /dev/null -w '%{http_code}\n' http://localhost:8080/biblioteca-fis/index.jsp
```

El cambio de WAR puede recargar el contexto y perder sesiones activas; no reiniciar Tomcat si se despliega automáticamente. **URL del servicio prevista, todavía no verificada para la app nueva:** `http://localhost:8080/biblioteca-fis/index.jsp`. Repetir allí las pruebas y consultar los logs del Tomcat principal después de publicar.

## Pruebas ejecutadas y logs

Se utilizó `curl` con archivos de cookies distintos en un directorio temporal eliminado al terminar; no se guardaron identificadores en documentos. Muestra reproducible **mientras siga activo el Tomcat aislado** (usar la URL del servicio al publicarlo):

```bash
base=http://127.0.0.1:18081/biblioteca-fis
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl --noproxy '*' -sS -o "$tmp/form.html" -w '%{http_code}\n' "$base/index.jsp"
curl --noproxy '*' -sS -b "$tmp/uno" -c "$tmp/uno" --data-urlencode 'nombre=Ana Torres' --data-urlencode 'correo=ana@example.org' -o "$tmp/primero.html" -w '%{http_code}\n' "$base/registro.jsp"
curl --noproxy '*' -sS -b "$tmp/uno" -c "$tmp/uno" --data-urlencode 'nombre=Luis Pérez' --data-urlencode 'correo=luis@example.org' -o "$tmp/segundo.html" -w '%{http_code}\n' "$base/registro.jsp"
curl --noproxy '*' -sS -b "$tmp/dos" -c "$tmp/dos" --data-urlencode 'nombre=Eva Sol' --data-urlencode 'correo=eva@example.org' -o "$tmp/otra-sesion.html" -w '%{http_code}\n' "$base/registro.jsp"
curl --noproxy '*' -sS -o /dev/null -w '%{http_code} %header{allow}\n' "$base/registro.jsp"
curl --noproxy '*' -sS -X PUT -o /dev/null -w '%{http_code} %header{allow}\n' "$base/registro.jsp"
curl --noproxy '*' -sS -X OPTIONS -o /dev/null -w '%{http_code} %header{allow}\n' "$base/registro.jsp"
curl --noproxy '*' -sS --data-urlencode 'nombre=   ' --data-urlencode 'correo=ana@example.org' -o /dev/null -w '%{http_code}\n' "$base/registro.jsp"
curl --noproxy '*' -sS --data-urlencode 'nombre=Ana' --data-urlencode 'nombre=Otra' --data-urlencode 'correo=ana@example.org' -o /dev/null -w '%{http_code}\n' "$base/registro.jsp"
curl --noproxy '*' -sS --data-urlencode 'nombre[]=Ana' --data-urlencode 'correo=ana@example.org' -o /dev/null -w '%{http_code}\n' "$base/registro.jsp"
curl --noproxy '*' -sS -o /dev/null -w '%{http_code} %{content_type}\n' "$base/styles.css"
curl --noproxy '*' -sS -o /dev/null -w '%{http_code} %{content_type}\n' "$base/assets/img/Fis.png"
```

| Prueba con el Tomcat aislado :18081 | Resultado observado |
| --- | --- |
| GET `index.jsp` | 200; título, formulario y acción `registro.jsp` visibles |
| POST válido / segundo POST misma cookie / nueva cookie | 200; Ana visible; luego Ana y Luis (fila n.º 2); nueva sesión solo Eva |
| Nombre vacío, solo espacios, correo inválido o campos ausentes | 400 y mensaje con enlace en todos los casos |
| Nombre duplicado, correo duplicado, `nombre[]` o `correo[]` | 400, sin excepción en la respuesta |
| Nombre de 101 caracteres o correo de 255 caracteres | 400 |
| GET, PUT y OPTIONS a `registro.jsp` | 405 y `Allow: POST` (al principio, antes de añadir el filtro, Jasper respondió PUT con `Allow: GET, HEAD, POST, OPTIONS` y OPTIONS con 200; **resuelto** mediante filtro) |
| Nombre `<script>alert('x') & "y"</script>` | 200, entidades `&lt;`, `&gt;`, `&amp;`, `&quot;`, `&#39;`; ninguna etiqueta ejecutable |
| `María Peña Ñúñez` | 200, texto UTF-8 conservado |
| POST válido tras casos inválidos | 200; solo 5 contactos válidos, sin filas añadidas por entradas inválidas |
| Dos POST simultáneos con la misma sesión | 200 ambos; posterior tabla incluye ambos y numeración hasta 8 |
| CSS y `Fis.png` | 200; contenido CSS y bytes PNG coinciden con archivos del repositorio |
| PHP | 200 en `http://127.0.0.1:18080/index.html` (PHP fase 2 aislado) y en `http://localhost:80/lab09-php/index.html` (app anterior); una cookie compartida entre PHP fase 2 y JSP mostró únicamente el registro propio en cada aplicación |
| `javac` del filtro y compilación JSP | Sin errores; se verificaron `.java`/`.class` de ambas JSP en `work/Catalina/localhost/biblioteca-fis/` |
| Empaquetado del WAR en directorio temporal | `jar --create` y `jar tf` correctos; presentes `index.jsp`, `registro.jsp`, CSS, PNG, `WEB-INF/web.xml` y `WEB-INF/classes/.../MetodoPostFilter.class` |

**Fallidas en la comprobación final del entorno de ensayo:** ninguna. **Bloqueo para el servicio principal:** URL nueva :8080 devuelve 404 porque la app no fue instalada; no se considera prueba aprobada del despliegue allí. El servicio principal continúa activo y sus logs solo documentan la app preexistente. En los logs del **Tomcat aislado** se observaron `HostConfig.deployDirectory` para `/tmp/opencode/tomcat-fis/webapps/biblioteca-fis` y `Server startup`; al agregar `web.xml` antes del `.class` hubo un mensaje transitorio `HostConfig.reload Falló la recarga del contexto [/biblioteca-fis]` a las 10:08:30, seguido por `StandardContext.reload Se ha completado la recarga de este Contexto` a las 10:08:31. La nueva prueba HTTP con filtro compilado devolvió 405/`Allow: POST`, y los POST posteriores devolvieron 200, sin error de compilación JSP observado. El WAR propuesto se prepara completo antes de publicarse para evitar esa situación.

**Pendientes:** verificar `appBase` literal con el comando privilegiado, publicar en :8080 y repetir casos con logs reales de ese servicio; revisión visual del formulario y tabla en navegador escritorio/móvil (el intento de captura automatizada en Brave agotó 30 s sin generar imagen); contraste/foco con Tab, y capturas. La aceptación docente de Apache nativo y auditoría conjunta son posteriores.

Guardar manualmente en `docs/evidencias/` sin cookies ni identificadores:

1. `fase03-01-formulario-jsp.png` — formulario y logo.
2. `fase03-02-registros-jsp.png` — tabla de dos registros en la misma sesión.
3. `fase03-03-validacion-jsp.png` — mensaje 400 y enlace.
4. `fase03-04-http-405-jsp.png` — 405 y `Allow: POST` (terminal o red del navegador, sin cookies).
5. `fase03-05-log-tomcat.png` — log del despliegue y ejecución del **Tomcat principal**, una vez instalado, ocultando datos sensibles.

No se generaron capturas entregables en esta fase.
