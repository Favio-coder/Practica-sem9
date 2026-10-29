# Laboratorio 09 — Biblioteca UNCP – FIS

**Autor:** Richard Favio Asturimac Medina (Ingeniería de Sistemas, UNCP).

Registro de contactos de la **Facultad de Ingeniería de Sistemas**: nombre y correo. Implementaciones PHP sobre Apache y JSP sobre Tomcat, cada una con su propia sesión. Sin base de datos ni autenticación.

## Estado

**Fase 3 JSP implementada en el repositorio y probada con Tomcat aislado; publicación en Tomcat principal pendiente por permisos y lectura de `appBase`.** La fase 2 PHP sigue accesible en el Apache aislado. Las aplicaciones previas en `/var/www/html/lab09-php` y `/var/lib/tomcat10/webapps/lab09-jsp` se conservaron.

Entorno documentado en fase 1: Linux Mint 22.2; Apache 2.4.58 en puerto 80 y DocumentRoot `/var/www/html`; Tomcat 10.1.55 en puerto 8080, `CATALINA_BASE=/var/lib/tomcat10`; PHP 8.3.6 y módulo Apache `php_module`. Se comprobó ejecución PHP por HTTP y compilación JSP por Tomcat aislado en puerto 18081. El valor literal de `appBase` en el `server.xml` del servicio sigue pendiente de lectura privilegiada; los logs muestran despliegues existentes desde `/var/lib/tomcat10/webapps`. Véase [entorno.md](docs/entorno.md).

> Se usa Apache nativo en vez de XAMPP; confirmar su aceptación con el docente.

## Estructura

```text
lab09-contactos/
├── php-app/{index.html,registro.php,styles.css,assets/img/Fis.png}
├── jsp-app/{index.jsp,registro.jsp,styles.css,assets/img/Fis.png}
├── jsp-app/WEB-INF/{web.xml,src/edu/uncp/biblioteca/MetodoPostFilter.java}
├── docs/
│   ├── fases.md
│   ├── entorno.md
│   ├── contrato-funcional.md
│   ├── fase-02-php.md
│   ├── fase-03-jsp.md
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

La revisión visual y las capturas de PHP y su publicación permanente continúan pendientes; la comparación y auditoría conjunta corresponden a la fase 4.

## JSP: despliegue y pruebas

El código fuente está en `jsp-app/`. Tomcat 10.1.55 compiló y atendió las JSP bajo `http://127.0.0.1:18081/biblioteca-fis/index.jsp` en una instancia temporal separada; esta URL respondió 200 y depende de que la instancia siga activa. El contexto **no** está publicado en el Tomcat principal: `http://localhost:8080/biblioteca-fis/index.jsp` respondió 404. Después de confirmar `appBase` con permisos, publicar un WAR nuevo sin tocar `ROOT` ni `lab09-jsp`; la URL prevista del servicio es `http://localhost:8080/biblioteca-fis/index.jsp` (pendiente de verificar).

Tomcat no incluye JSTL aquí: `registro.jsp` valida el POST, conserva registros en `session` y escapa HTML al mostrar la tabla. Un filtro Jakarta limitado a `/registro.jsp` responde 405 con `Allow: POST` para los métodos que Jasper interceptaría antes de la JSP. Es necesario compilarlo con el `servlet-api.jar` de Tomcat antes de empaquetar la aplicación. Comandos de compilación, publicación, pruebas, logs y capturas: [docs/fase-03-jsp.md](docs/fase-03-jsp.md).

Siguen pendientes la revisión visual y las capturas; la comparación exhaustiva y auditoría conjunta corresponden a la fase 4.
