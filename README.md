# Laboratorio 09 — Sistema de Registro de Contacto

**Autor:** Richard Favio Asturimac Medina (Ingeniería de Sistemas, UNCP).

Dos implementaciones del mismo registro de contacto: PHP sobre Apache nativo y JSP sobre Tomcat. Los requisitos acordados son formulario de nombre y correo, envío POST, validación del lado del servidor, almacenamiento temporal por sesión, tabla de registros y comportamiento HTTP comparable. Se documentarán el ciclo HTTP, la seguridad básica, las pruebas y la matriz comparativa PHP vs JSP.

## Estado

**Fase 1 parcialmente completada:** estructura y contrato preparados; diagnóstico local realizado, con verificaciones de permisos pendientes en [docs/entorno.md](docs/entorno.md). No hay formulario ni lógica de registro en este proyecto. Proyectos preexistentes en `/var/www/html/lab09-php` y `/var/lib/tomcat10/webapps/lab09-jsp` se conservan.

Entorno verificado el 2026-10-29 (America/Lima): Linux Mint 22.2; Apache 2.4.58 activo y HTTP 200 en puerto 80; Tomcat 10.1.55 activo y HTTP 200 en puerto 8080; Java 21.0.12.1; PHP CLI 8.3.6 y módulo Apache `php_module` con controlador PHP 8.3. Apache usa el VirtualHost por defecto y `/var/www/html`; Tomcat usa `CATALINA_BASE=/var/lib/tomcat10`. Quedan pendientes la atribución privilegiada de procesos a los sockets, la lectura de `appBase` de Tomcat y una prueba HTTP de ejecución PHP; véase [entorno.md](docs/entorno.md). La disponibilidad del módulo no sustituye una prueba HTTP de ejecución PHP.

> Se usa Apache nativo en vez de XAMPP; confirmar su aceptación con el docente.

## Estructura

```text
lab09-contactos/
├── php-app/.gitkeep
├── jsp-app/.gitkeep
├── docs/
│   ├── fases.md
│   ├── entorno.md
│   ├── contrato-funcional.md
│   └── evidencias/.gitkeep
├── scripts/diagnostico.sh
├── README.md
└── .gitignore
```

`bash scripts/diagnostico.sh` repite comprobaciones de solo lectura sin solicitar sudo. Para las comprobaciones pendientes, seguir los comandos acotados de `docs/entorno.md`. Plan y responsabilidades: [docs/fases.md](docs/fases.md); respuestas HTTP y validación: [docs/contrato-funcional.md](docs/contrato-funcional.md).

## Despliegue (pendiente)

Documentar rutas, permisos de despliegue y URLs de ambas implementaciones tras confirmar las rutas necesarias.

## Pruebas (pendiente)

Documentar casos HTTP, sesiones, validación y evidencias sin publicar datos privados.

## Ciclo HTTP (pendiente)

Explicar petición, procesamiento, sesión y respuesta para PHP y JSP.

## Comparativa PHP vs JSP (pendiente)

Completar matriz comparativa basada en las dos implementaciones y sus pruebas.
