# Diagnóstico del entorno — fase 1

**Comprobado:** 2026-10-29, entre 09:35 y 09:43, zona `America/Lima` (UTC-05:00; `date --iso-8601=seconds` y `timedatectl show --property=Timezone`). Se ejecutó en el equipo accesible bajo `/home/favio-coder`; `systemd-detect-virt` devolvió `none` (no detectó virtualización; no demuestra por sí solo identidad física). No se usó sudo con éxito, no se instalaron paquetes ni se reiniciaron servicios.

| Comando de solo lectura | Resultado observado | Significado / límite |
| --- | --- | --- |
| Lectura de `/etc/os-release` | Linux Mint 22.2 (Zara), base Ubuntu noble | Distribución del sistema accesible |
| `systemctl status apache2.service tomcat10.service --no-pager --full` y `systemctl show ... --property=FragmentPath,ActiveState,SubState,MainPID` | Ambos `active (running)` desde 09:04:52 -05; Apache PID principal 1344; Tomcat PID principal 1330; unidades `/usr/lib/systemd/system/{apache2,tomcat10}.service` | Estado sin truncamiento; Tomcat muestra Java 21 y arranque `http-nio-8080` |
| `ss -ltnp` | Escucha `*:80` y `*:8080`; columna de proceso vacía en esos sockets | Puertos comprobados; atribuir cada socket a un proceso mediante `ss` requiere permisos adicionales; servicio y respuesta HTTP respaldan la asociación, no la prueban por PID de socket |
| `java -version` | OpenJDK 21.0.12.1 | Versión del ejecutable Java; `systemctl status` muestra `/usr/lib/jvm/java-21-openjdk-amd64/bin/java` para Tomcat |
| `php --version` | PHP 8.3.6 (CLI) en `/usr/bin/php` | Disponibilidad CLI; **no prueba** ejecución PHP mediante Apache |
| `apache2ctl -v; apache2ctl -M; apache2ctl -S` y lectura de `/etc/apache2/mods-enabled/php8.3.{load,conf}` | Apache/2.4.58 (Ubuntu), `php_module (shared)` con `libphp8.3.so`, `SetHandler application/x-httpd-php`; VirtualHost `*:80` en `000-default.conf`, DocumentRoot `/var/www/html` | PHP configurado mediante módulo Apache (no hay unidad `php*-fpm.service` listada); falta prueba HTTP ejecutando un PHP de prueba controlado en fase 2 |
| `systemctl list-units --all --type=service 'php*-fpm.service'; systemctl list-unit-files 'php*-fpm.service'` | 0 unidades / 0 archivos de unidad listados (este último comando devolvió código 1 por no encontrar coincidencias) | No se observó PHP-FPM como servicio del sistema; mecanismo Apache comprobado: módulo |
| Lectura de `/etc/apache2/sites-enabled/000-default.conf` | Único sitio habilitado `000-default.conf`; `<VirtualHost *:80>`, `DocumentRoot /var/www/html`; `ServerName` de ejemplo comentado | Para `localhost:80` aplica el sitio por defecto; no se modificó |
| `systemctl status tomcat10.service --no-pager --full`; `readlink -f /var/lib/tomcat10/{conf,webapps}`; lectura de `/var/lib/tomcat10/webapps` | JVM con `-Dcatalina.base=/var/lib/tomcat10` y `-Dcatalina.home=/usr/share/tomcat10`; ruta real `/var/lib/tomcat10/webapps`; Tomcat registra despliegues allí de `ROOT` y `lab09-jsp` | CATALINA_BASE verificado y directorio usado en despliegues observado; `appBase` exacto de `server.xml` sigue pendiente por permisos |
| Lectura de `/etc/tomcat10/server.xml` | Denegada: `-rw-r----- root:tomcat` | No se pudieron verificar directamente `<Host appBase>` ni otros atributos de `server.xml`; no inferirlos del directorio existente |
| `curl --noproxy '*' --max-time 10 --silent --show-error --output /dev/null --write-out ... http://localhost:80/` | HTTP 200, destino `::1:80` | Responde Apache en loopback; solo comprueba página `/`, no PHP |
| Igual consulta a `http://localhost:8080/` | HTTP 200, destino `::1:8080` | Responde Tomcat en loopback; solo comprueba página `/`, no JSP nuevo |
| `git --version; curl --version` | Git 2.56.0; curl 8.5.0 | Herramientas disponibles |
| `git -C /home/favio-coder/universidad rev-parse --show-toplevel` y consulta desde el proyecto nuevo | No pertenece a un repositorio padre (error «no es un repositorio git») | Se puede inicializar Git local en el proyecto nuevo sin anidar repositorios |
| `git init; git status --short --untracked-files=all; git remote -v` desde el proyecto nuevo | Repositorio local inicializado; nueve archivos nuevos sin seguimiento; sin remotos y sin commits | La estructura queda lista para control de versiones, sin publicar ni confirmar cambios automáticamente |
| Lectura de `/var/www/html` y `/var/lib/tomcat10/webapps` | Ya existen `lab09-php/` y `lab09-jsp/` respectivamente | Son trabajo previo: no se modificó ni eliminó |

**Mensaje completo AH00558:** `AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 127.0.1.1. Set the 'ServerName' directive globally to suppress this message`. Apareció en el arranque y al inspeccionar Apache; es una advertencia sobre el nombre de servidor, no un fallo de arranque: el servicio está activo y responde HTTP 200. No se propone cambiar configuración global en esta fase.

## Pendientes concretos

1. Confirmar PID y programa de cada socket con `sudo ss -ltnp '( sport = :80 or sport = :8080 )'`. Finalidad: ver asociación proceso/puerto que el usuario normal no puede mostrar. `sudo -n` devolvió «se requiere una contraseña»; ejecutar de forma local con credenciales, sin copiar otros sockets al informe.
2. Confirmar la configuración efectiva del despliegue Tomcat con `sudo grep -nE '<Host|appBase=|<Connector' /etc/tomcat10/server.xml`. Finalidad: ver el `appBase` declarado y el conector sin volcar configuraciones enteras. Su lectura requiere permiso root o grupo tomcat. La ruta `/var/lib/tomcat10/webapps` ya está comprobada por despliegues existentes, pero no el valor literal de `appBase`.
3. En fase 2, comprobar ejecución PHP **por HTTP** con un archivo de prueba acotado en la ruta de despliegue aprobada y retirarlo tras comprobarlo; el CLI y `php_module` no constituyen una prueba funcional del procesamiento HTTP. Confirmar permisos/ruta de publicación sin tocar el proyecto anterior.
4. Consultar al docente si Apache nativo se acepta en lugar de XAMPP antes de cerrar la documentación de entrega.

No se supone que `lab09-contactos/` bajo el HOME sea servido automáticamente por Apache o Tomcat; el despliegue se decidirá en fases posteriores.
