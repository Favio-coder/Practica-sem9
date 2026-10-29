package edu.uncp.biblioteca;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

/** Jasper intercepta PUT/OPTIONS antes de ejecutar JSP; aquí se unifica el 405. */
public final class MetodoPostFilter implements Filter {
    @Override
    public void doFilter(ServletRequest solicitud, ServletResponse respuesta, FilterChain cadena)
            throws IOException, ServletException {
        HttpServletRequest request = (HttpServletRequest) solicitud;
        HttpServletResponse response = (HttpServletResponse) respuesta;
        if ("POST".equals(request.getMethod())) {
            cadena.doFilter(solicitud, respuesta);
            return;
        }

        response.setStatus(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
        response.setHeader("Allow", "POST");
        response.setHeader("Cache-Control", "no-store");
        response.setContentType("text/html; charset=UTF-8");
        response.getWriter().write("""
            <!doctype html>
            <html lang="es">
            <head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1">
              <title>Método no permitido | Biblioteca UNCP – FIS</title>
              <link rel="stylesheet" href="styles.css"></head>
            <body><main class="shell"><section class="card" aria-labelledby="page-title">
              <header class="identity">
                <img class="identity__image" src="assets/img/Fis.png" alt="Emblema de la Facultad de Ingeniería de Sistemas de la UNCP" width="150" height="150">
                <div><p class="identity__faculty">Facultad de Ingeniería de Sistemas</p>
                  <h1 id="page-title">Biblioteca UNCP – FIS</h1><p class="subtitle">Registro de contactos</p></div>
              </header>
              <div class="card__body"><div role="alert" class="message"><h2>Método no permitido</h2>
                <p>Envía el formulario para registrar un contacto.</p></div>
                <a class="back" href="index.jsp">Registrar otro contacto</a>
                <p class="note">Los registros se conservan temporalmente durante tu sesión</p>
              </div>
            </section></main></body></html>
            """);
    }
}
