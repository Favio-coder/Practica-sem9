# Contrato funcional compartido — PHP y JSP

Este contrato guía ambas implementaciones y sus pruebas futuras; todavía no hay endpoints implementados.

| Aspecto | Comportamiento acordado |
| --- | --- |
| Campos | `nombre` y `correo` |
| Envío | Formulario mediante `POST` a `registro.php` o `registro.jsp`, respectivamente |
| POST válido | HTTP 200 y tabla con los registros de la sesión de navegador |
| Otro método en el endpoint | HTTP 405 y cabecera `Allow: POST` |
| Campos ausentes, vacíos o inválidos | HTTP 400 y mensaje comprensible |
| Validación | En servidor, con independencia de validaciones HTML; misma política de validación en PHP y JSP |
| Presentación | Escapar como HTML al mostrar datos; conservar los valores validados sin preescaparlos |
| Persistencia | Solo sesión, sin base de datos; registros aislados entre sesiones de navegador |
| Equivalencia | Mismo comportamiento observable, estados HTTP y política de validación en ambas aplicaciones |
| Fallos inesperados | HTTP 500 sin mostrar trazas al usuario; pruebas 500 controladas, sin endpoints inseguros persistentes para provocarlos |

La consigna usa `registro.*` y el ejemplo usa `procesar.*`: se adopta **`registro.php` / `registro.jsp`** por consistencia. Las reglas detalladas y compartidas de validez (por ejemplo, límites de longitud) se concretarán antes de implementar y se probarán por igual en ambas aplicaciones.
