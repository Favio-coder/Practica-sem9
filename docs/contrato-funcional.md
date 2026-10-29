# Contrato funcional compartido — PHP y JSP

Este contrato guía ambas implementaciones; `registro.php` está implementado en fase 2 y `registro.jsp` queda para fase 3.

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

La consigna usa `registro.*` y el ejemplo usa `procesar.*`: se adopta **`registro.php` / `registro.jsp`** por consistencia. Política concretada en fase 2 para repetir en JSP: recortar espacios en los extremos; nombre de 1 a 100 caracteres UTF-8, sin controles; correo no vacío de hasta 254 caracteres UTF-8 y válido como dirección electrónica; rechazar campos ausentes o arrays. Véase `docs/fase-02-php.md`.
