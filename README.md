# Laboratorio 09 — Biblioteca UNCP – FIS

**Autor:** Richard Favio Asturimac Medina (Ingeniería de Sistemas, UNCP).

Registro de contactos de la **Facultad de Ingeniería de Sistemas**: nombre y correo. La implementación PHP funciona con Apache; la implementación JSP sobre Tomcat corresponde a una fase posterior. Sin base de datos ni autenticación.

## Estado

**Fase 2 implementada en el repositorio y probada en Apache aislado; publicación permanente pendiente por permisos.** Se comprobaron los archivos existentes de fase 1 (`docs/entorno.md`, `docs/fases.md`, `docs/contrato-funcional.md`, estructura y script); persisten las verificaciones de entorno pendientes allí anotadas. Las aplicaciones preexistentes en `/var/www/html/lab09-php` y `/var/lib/tomcat10/webapps/lab09-jsp` no se tocaron.

Entorno documentado en fase 1: Linux Mint 22.2; Apache 2.4.58 en puerto 80 y DocumentRoot `/var/www/html`; Tomcat en puerto 8080; PHP 8.3.6 y módulo Apache `php_module`. En fase 2 se confirmó ejecución PHP por HTTP en Apache (puerto 80, aplicación previa; puerto 18080, código nuevo). Quedan pendientes la atribución privilegiada de sockets y la lectura de `appBase` de Tomcat; véase [entorno.md](docs/entorno.md).

> Se usa Apache nativo en vez de XAMPP; confirmar su aceptación con el docente.

## Estructura

```text
lab09-contactos/
├── php-app/{index.html,registro.php,styles.css,assets/img/Fis.png}
├── jsp-app/assets/img/Fis.png
├── docs/
│   ├── fases.md
│   ├── entorno.md
│   ├── contrato-funcional.md
│   ├── fase-02-php.md
│   └── evidencias/.gitkeep
├── scripts/diagnostico.sh
├── README.md
└── .gitignore
```

`bash scripts/diagnostico.sh` repite comprobaciones de solo lectura sin solicitar sudo. Para las comprobaciones pendientes, seguir `docs/entorno.md`. Plan: [docs/fases.md](docs/fases.md); contrato HTTP: [docs/contrato-funcional.md](docs/contrato-funcional.md).

## PHP: despliegue y pruebas

El código fuente está en `php-app/`. En una sesión con permisos de administración, publicarlo en un directorio **nuevo** `/var/www/html/lab09-contactos-php/` sin modificar `/var/www/html/lab09-php/`; luego abrir `http://localhost:80/lab09-contactos-php/index.html`. Esta URL permanente **aún no está verificada**: `/var/www/html` pertenece a root y `sudo -n` pidió contraseña.

La URL `http://127.0.0.1:18080/index.html` **sí respondió 200** durante las pruebas en una instancia local aislada de Apache que sirve `php-app/` directamente (puerto temporal distinto del sitio permanente). Su disponibilidad depende de que esa instancia siga en ejecución. Pasos de publicación, comandos de prueba, resultados y pendientes: [docs/fase-02-php.md](docs/fase-02-php.md).

El formulario envía `POST` a `registro.php`; PHP valida los datos antes de abrir la sesión, agrega el contacto en `$_SESSION['registros']` y muestra la tabla escapando los datos al generar HTML. Las entradas inválidas reciben 400; métodos distintos de POST reciben 405 con `Allow: POST`.

La revisión visual, las capturas de pantalla, la publicación permanente y la comparativa con JSP quedan para las fases correspondientes.
