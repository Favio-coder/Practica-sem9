<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %><%@ page import="java.util.ArrayList,java.util.HashMap,java.util.List,java.util.Map,java.util.regex.Pattern" %><%!
    private static final Pattern CORREO = Pattern.compile(
        "^[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*"
        + "@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?"
        + "(?:\\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*$"
    );

    private String recortar(String valor) {
        // Los caracteres exteriores que trim() elimina en la versión PHP.
        int inicio = 0;
        int fin = valor.length();
        while (inicio < fin && (valor.charAt(inicio) == ' ' || valor.charAt(inicio) == '\n'
                || valor.charAt(inicio) == '\r' || valor.charAt(inicio) == '\t'
                || valor.charAt(inicio) == '\u000B' || valor.charAt(inicio) == '\u0000')) inicio++;
        while (fin > inicio && (valor.charAt(fin - 1) == ' ' || valor.charAt(fin - 1) == '\n'
                || valor.charAt(fin - 1) == '\r' || valor.charAt(fin - 1) == '\t'
                || valor.charAt(fin - 1) == '\u000B' || valor.charAt(fin - 1) == '\u0000')) fin--;
        return valor.substring(inicio, fin);
    }

    private boolean nombreValido(String nombre) {
        int longitud = nombre.codePointCount(0, nombre.length());
        if (longitud < 1 || longitud > 100) return false;
        for (int i = 0; i < nombre.length();) {
            int punto = nombre.codePointAt(i);
            if (punto <= 0x1F || punto == 0x7F
                    || (punto >= 0xD800 && punto <= 0xDFFF)) return false;
            i += Character.charCount(punto);
        }
        return true;
    }

    private String escapar(String valor) {
        StringBuilder html = new StringBuilder(valor.length());
        for (int i = 0; i < valor.length(); i++) {
            switch (valor.charAt(i)) {
                case '&': html.append("&amp;"); break;
                case '<': html.append("&lt;"); break;
                case '>': html.append("&gt;"); break;
                case '"': html.append("&quot;"); break;
                case '\'': html.append("&#39;"); break;
                default: html.append(valor.charAt(i));
            }
        }
        return html.toString();
    }
%><%
    request.setCharacterEncoding("UTF-8");
    response.setHeader("Cache-Control", "no-store");
    String problema = null;
    List<Map<String, String>> copia = null;
    try {
        if (!"POST".equals(request.getMethod())) {
            response.setHeader("Allow", "POST");
            response.setStatus(405);
            problema = "Método no permitido";
        } else {
            String[] nombres = request.getParameterValues("nombre");
            String[] correos = request.getParameterValues("correo");
            String nombre = request.getParameter("nombre");
            String correo = request.getParameter("correo");
            boolean inesperados = false;
            for (String clave : request.getParameterMap().keySet()) {
                if (!"nombre".equals(clave) && !"correo".equals(clave)) inesperados = true;
            }

            if (inesperados || nombres == null || nombres.length != 1
                    || correos == null || correos.length != 1
                    || nombre == null || correo == null) {
                response.setStatus(400);
                problema = "Datos inválidos";
            } else {
                nombre = recortar(nombre);
                correo = recortar(correo);
                if (!nombreValido(nombre) || correo.isEmpty()
                        || correo.codePointCount(0, correo.length()) > 254
                        || !CORREO.matcher(correo).matches()) {
                    response.setStatus(400);
                    problema = "Datos inválidos";
                } else {
                    // La colección pertenece a esta sesión; la copia evita iterar mientras se modifica.
                    synchronized (session) {
                        @SuppressWarnings("unchecked")
                        List<Map<String, String>> registros =
                            (List<Map<String, String>>) session.getAttribute("registros");
                        if (registros == null) {
                            registros = new ArrayList<>();
                            session.setAttribute("registros", registros);
                        }
                        synchronized (registros) {
                            Map<String, String> contacto = new HashMap<>();
                            contacto.put("nombre", nombre);
                            contacto.put("correo", correo);
                            registros.add(contacto);
                            copia = new ArrayList<>(registros);
                        }
                    }
                    response.setStatus(200);
                }
            }
        }
    } catch (RuntimeException error) {
        // Nunca mostrar el detalle interno en la respuesta HTTP.
        response.setStatus(500);
        problema = "Servicio no disponible";
        copia = null;
    }
%><!doctype html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title><%= problema == null ? "Contactos registrados" : escapar(problema) %> | Biblioteca UNCP – FIS</title>
  <link rel="stylesheet" href="styles.css">
</head>
<body>
  <main class="shell">
    <section class="card" aria-labelledby="page-title">
      <header class="identity">
        <img class="identity__image" src="assets/img/Fis.png" alt="Emblema de la Facultad de Ingeniería de Sistemas de la UNCP" width="150" height="150">
        <div>
          <p class="identity__faculty">Facultad de Ingeniería de Sistemas</p>
          <h1 id="page-title">Biblioteca UNCP – FIS</h1>
          <p class="subtitle">Registro de contactos</p>
        </div>
      </header>
      <div class="card__body">
<% if (problema != null) { %>
        <div role="alert" class="message">
          <h2><%= escapar(problema) %></h2>
          <p><%= "Método no permitido".equals(problema) ? "Envía el formulario para registrar un contacto."
              : "Servicio no disponible".equals(problema) ? "Inténtalo de nuevo más tarde."
              : "El nombre debe tener entre 1 y 100 caracteres y el correo debe ser válido y tener como máximo 254 caracteres." %></p>
        </div>
<% } else { %>
        <h2>Contactos registrados</h2>
        <p>Estos son los contactos registrados en tu sesión.</p>
        <div class="table-scroll">
          <table>
            <caption>Contactos de esta sesión</caption>
            <thead><tr><th scope="col">N.º</th><th scope="col">Nombre</th><th scope="col">Correo</th></tr></thead>
            <tbody>
<% for (int i = 0; i < copia.size(); i++) { Map<String, String> contacto = copia.get(i); %>
              <tr><th scope="row"><%= i + 1 %></th><td><%= escapar(contacto.get("nombre")) %></td><td><%= escapar(contacto.get("correo")) %></td></tr>
<% } %>
            </tbody>
          </table>
        </div>
<% } %>
        <a class="back" href="index.jsp">Registrar otro contacto</a>
        <p class="note">Los registros se conservan temporalmente durante tu sesión</p>
      </div>
    </section>
  </main>
</body>
</html>
