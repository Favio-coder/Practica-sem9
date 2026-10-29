#!/usr/bin/env bash
# Diagnóstico de solo lectura; nunca eleva permisos ni modifica servicios.
set -u

check() {
    local title="$1" cmd="$2"
    shift 2
    printf '\n== %s ==\n' "$title"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        printf 'PENDIENTE: no se encuentra el comando %s\n' "$cmd"
        return 0
    fi
    "$@"
    local result=$?
    if (( result != 0 )); then
        printf 'PENDIENTE/FALLO: %s devolvió código %d; revisar salida anterior.\n' "$cmd" "$result"
    fi
    return 0
}

check 'Fecha y zona horaria' date date --iso-8601=seconds
check 'Zona configurada' timedatectl timedatectl show --property=Timezone
printf '\n== Distribución (/etc/os-release) ==\n'
if [[ -r /etc/os-release ]]; then
    while IFS= read -r line; do
        case "$line" in PRETTY_NAME=*|VERSION_ID=*|UBUNTU_CODENAME=*) printf '%s\n' "$line" ;; esac
    done < /etc/os-release
else
    printf 'PENDIENTE: /etc/os-release no es legible.\n'
fi
check 'Estado completo de Apache' systemctl systemctl status apache2.service --no-pager --full
check 'Estado completo de Tomcat' systemctl systemctl status tomcat10.service --no-pager --full
check 'Puertos escuchando y procesos visibles sin sudo' ss ss -ltnp
check 'Versión de Java' java java -version
check 'Versión PHP CLI (no demuestra ejecución HTTP)' php php --version
check 'Versión de Apache' apache2ctl apache2ctl -v
check 'Módulos Apache (PHP módulo o proxy FPM)' apache2ctl apache2ctl -M
check 'VirtualHost y DocumentRoot' apache2ctl apache2ctl -S
printf '\n== Configuración de sitio y controlador PHP (si son legibles) ==\n'
for file in /etc/apache2/sites-enabled/000-default.conf /etc/apache2/mods-enabled/php8.3.conf /etc/apache2/mods-enabled/php8.3.load; do
    if [[ -r "$file" ]]; then
        check "Lectura de $file" cat cat "$file"
    else
        printf 'PENDIENTE: %s no existe o no es legible.\n' "$file"
    fi
done
check 'Servicios PHP-FPM registrados' systemctl systemctl list-units --all --type=service 'php*-fpm.service' --no-pager --full
printf '\n== CATALINA_BASE y despliegue observado ==\n'
printf 'Comprobar -Dcatalina.base en el estado completo de Tomcat anterior.\n'
check 'Ruta real de webapps' readlink readlink -f /var/lib/tomcat10/webapps
check 'Aplicaciones presentes en webapps' ls ls -ld /var/lib/tomcat10/webapps /var/lib/tomcat10/webapps/*
if [[ -r /etc/tomcat10/server.xml ]]; then
    check 'Host, appBase y Connector de Tomcat' grep grep -nE '<Host|appBase=|<Connector' /etc/tomcat10/server.xml
else
    printf 'PENDIENTE: /etc/tomcat10/server.xml no es legible sin permisos adicionales.\n'
fi
check 'Apache HTTP / (puerto 80 observado en fase 1; confirmar en ss)' curl curl --noproxy '*' --max-time 10 --silent --show-error --output /dev/null --write-out 'HTTP %{http_code} en %{remote_ip}:%{remote_port}\n' http://localhost:80/
check 'Tomcat HTTP / (puerto 8080 observado en fase 1; confirmar en ss)' curl curl --noproxy '*' --max-time 10 --silent --show-error --output /dev/null --write-out 'HTTP %{http_code} en %{remote_ip}:%{remote_port}\n' http://localhost:8080/
check 'Git disponible' git git --version
check 'curl disponible' curl curl --version
printf '\nFin: revisar advertencias y pendientes; HTTP 200 en / no prueba PHP ni JSP.\n'
