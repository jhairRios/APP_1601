<?php
// Configuración de la base de datos (Amazon RDS)
$host = 'mi-mysql-db.c6j6ewui4d46.us-east-1.rds.amazonaws.com';
$port = 3306;
$user = 'admin';
$password = 'JhairRios_2005';
$db = 'App1601';

$conn = new mysqli($host, $user, $password, $db, $port);

if ($conn->connect_error) {
    die("Conexión fallida: " . $conn->connect_error);
}

// Establecer charset utf8mb4
if (! $conn->set_charset('utf8mb4')) {
    // No detener la ejecución; solo dejar registro en caso de debugging
    error_log('Warning: no se pudo establecer charset utf8mb4: ' . $conn->error);
}
// La conexión fue exitosa
?>
