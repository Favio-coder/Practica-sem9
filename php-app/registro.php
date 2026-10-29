<?php
declare(strict_types=1);

ini_set('display_errors', '0');
header('Content-Type: text/html; charset=UTF-8');
header('Cache-Control: no-store');

function escapar(string $valor): string
{
    return htmlspecialchars($valor, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

function mostrarPagina(string $titulo, string $contenido): void
{
    $tituloSeguro = escapar($titulo);
    echo <<<HTML
<!doctype html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{$tituloSeguro} | Biblioteca UNCP – FIS</title>
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
        {$contenido}
        <a class="back" href="index.html">Registrar otro contacto</a>
        <p class="note">Los registros se conservan temporalmente durante tu sesión</p>
      </div>
    </section>
  </main>
</body>
</html>
HTML;
}

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
    header('Allow: POST');
    http_response_code(405);
    mostrarPagina('Método no permitido', '<div role="alert" class="message"><h2>Método no permitido</h2><p>Envía el formulario para registrar un contacto.</p></div>');
    exit;
}

// PHP normaliza los escalares repetidos en $_POST. En el formulario URL-encoded
// se revisan las claves originales para rechazar duplicados y campos inesperados.
$tipoContenido = $_SERVER['CONTENT_TYPE'] ?? '';
if (preg_match('~^application/x-www-form-urlencoded(?:\s*;|\s*$)~i', $tipoContenido)) {
    $cuerpo = file_get_contents('php://input');
    if ($cuerpo === false) {
        http_response_code(500);
        mostrarPagina('Error del servicio', '<div role="alert" class="message"><h2>Servicio no disponible</h2><p>Inténtalo de nuevo más tarde.</p></div>');
        exit;
    }

    $clavesVistas = [];
    foreach (explode('&', $cuerpo) as $segmento) {
        $clave = urldecode(explode('=', $segmento, 2)[0]);
        if (($clave !== 'nombre' && $clave !== 'correo') || isset($clavesVistas[$clave])) {
            http_response_code(400);
            mostrarPagina('Datos inválidos', '<div role="alert" class="message"><h2>Datos inválidos</h2><p>Ingresa un nombre y un correo válidos, sin campos repetidos.</p></div>');
            exit;
        }
        $clavesVistas[$clave] = true;
    }
}

// FILTER_REQUIRE_SCALAR rechaza nombre[] y correo[] sin convertirlos en cadenas.
$nombre = filter_input(INPUT_POST, 'nombre', FILTER_UNSAFE_RAW, FILTER_REQUIRE_SCALAR);
$correo = filter_input(INPUT_POST, 'correo', FILTER_UNSAFE_RAW, FILTER_REQUIRE_SCALAR);

if (!is_string($nombre) || !is_string($correo)) {
    http_response_code(400);
    mostrarPagina('Datos inválidos', '<div role="alert" class="message"><h2>Datos inválidos</h2><p>Ingresa un nombre y un correo válidos.</p></div>');
    exit;
}

$nombre = trim($nombre);
$correo = trim($correo);

// Límites compartidos con el formulario: 1–100 caracteres para nombre,
// 1–254 caracteres para correo; la comprobación del servidor es la decisiva.
if ($nombre === '' || $correo === ''
    || !mb_check_encoding($nombre, 'UTF-8') || !mb_check_encoding($correo, 'UTF-8')
    || mb_strlen($nombre, 'UTF-8') > 100 || mb_strlen($correo, 'UTF-8') > 254
    || preg_match('/[\x00-\x1F\x7F]/u', $nombre)
    || filter_var($correo, FILTER_VALIDATE_EMAIL) === false) {
    http_response_code(400);
    mostrarPagina('Datos inválidos', '<div role="alert" class="message"><h2>Datos inválidos</h2><p>El nombre debe tener entre 1 y 100 caracteres y el correo debe ser válido y tener como máximo 254 caracteres.</p></div>');
    exit;
}

try {
    if (!@session_start()) {
        throw new RuntimeException('No se pudo iniciar la sesión');
    }
} catch (Throwable $error) {
    http_response_code(500);
    mostrarPagina('Error del servicio', '<div role="alert" class="message"><h2>Servicio no disponible</h2><p>Inténtalo de nuevo más tarde.</p></div>');
    exit;
}

if (!isset($_SESSION['registros']) || !is_array($_SESSION['registros'])) {
    $_SESSION['registros'] = [];
}
$_SESSION['registros'][] = ['nombre' => $nombre, 'correo' => $correo];

$filas = '';
foreach ($_SESSION['registros'] as $indice => $registro) {
    $numero = $indice + 1;
    $nombreSeguro = escapar($registro['nombre']);
    $correoSeguro = escapar($registro['correo']);
    $filas .= "<tr><th scope=\"row\">{$numero}</th><td>{$nombreSeguro}</td><td>{$correoSeguro}</td></tr>\n";
}

http_response_code(200);
mostrarPagina('Contactos registrados', <<<HTML
<h2>Contactos registrados</h2>
<p>Estos son los contactos registrados en tu sesión.</p>
<div class="table-scroll">
  <table>
    <caption>Contactos de esta sesión</caption>
    <thead><tr><th scope="col">N.º</th><th scope="col">Nombre</th><th scope="col">Correo</th></tr></thead>
    <tbody>{$filas}</tbody>
  </table>
</div>
HTML);
