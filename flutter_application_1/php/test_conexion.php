<?php
include 'conexion.php';
header('Content-Type: application/json');
echo json_encode(["mensaje" => "Conexión exitosa"]);
$conn->close();
?>
