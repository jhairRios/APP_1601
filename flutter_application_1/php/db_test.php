<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$host = 'mi-mysql-db.c6j6ewui4d46.us-east-1.rds.amazonaws.com';
$port = '3306';
$dbname = 'App1601';
$username = 'admin';
$password = 'JhairRios_2005';

try {
    $dsn = "mysql:host={$host};port={$port};dbname={$dbname};charset=utf8mb4";
    $pdo = new PDO($dsn, $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $stmt = $pdo->prepare("SELECT Restaurante_ID, Nombre, Logo, Direccion, Telefono, Correo FROM restaurante LIMIT 1");
    $stmt->execute();
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    echo json_encode(['ok' => true, 'message' => 'DB connection OK', 'row' => $row]);
} catch (PDOException $e) {
    echo json_encode(['ok' => false, 'message' => 'DB error: ' . $e->getMessage()]);
} catch (Exception $e) {
    echo json_encode(['ok' => false, 'message' => 'General error: ' . $e->getMessage()]);
}
