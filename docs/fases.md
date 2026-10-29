# Plan de fases

Responsable inicial: **Richard Favio Asturimac Medina**. El equipo puede asignar colaboradores concretos cuando acuerde el reparto; no se atribuye trabajo a personas sin confirmación.

| Fase | Responsable | Alcance | Entregables | Criterio de finalización |
| --- | --- | --- | --- | --- |
| 1. Entorno y estructura | Richard Favio Asturimac Medina | Diagnóstico de solo lectura, proyecto nuevo, decisiones y pendientes | Estructura, `README.md`, `docs/entorno.md`, contrato y script de diagnóstico | Archivos presentes y revisados; verificaciones privilegiadas de sockets y `appBase` aún pendientes según `docs/entorno.md` |
| 2. Implementación PHP | Richard Favio Asturimac Medina; colaboradores por definir | Formulario, procesamiento, validación y sesión PHP según contrato | `php-app/`, imágenes, `docs/fase-02-php.md` | Código y pruebas HTTP en Apache aislado realizados; despliegue en DocumentRoot del puerto 80, revisión visual y capturas pendientes por permisos/acceso a navegador |
| 3. Implementación JSP | Richard Favio Asturimac Medina; colaboradores por definir | Formulario, procesamiento, validación y sesión JSP según contrato | Código en `jsp-app/`, instrucciones de despliegue y evidencia de comportamiento | Casos JSP del contrato verificados con Tomcat y registrados |
| 4. QA y seguridad | Richard Favio Asturimac Medina; colaboradores por definir | Pruebas de métodos, datos, sesiones y escape HTML; fallos 500 controlados | Resultados reproducibles, incidencias y evidencias en `docs/evidencias/` | Pruebas comparables en ambas aplicaciones, incidencias tratadas o documentadas |
| 5. Documentación y entrega | Richard Favio Asturimac Medina; colaboradores por definir | Ciclo HTTP, matriz PHP/JSP, revisión final de guía y evidencias | README final, documentación, matriz y material de entrega | Entrega revisada, fuentes y evidencias coherentes y aceptación docente de Apache nativo confirmada |
