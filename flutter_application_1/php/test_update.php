<?php
// Test de actualización directa
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// Configuración de la base de datos
$host = 'mi-mysql-db.c6j6ewui4d46.us-east-1.rds.amazonaws.com';
$port = '3306';
$dbname = 'App1601';
$username = 'admin';
$password = 'JhairRios_2005';

try {
    $dsn = "mysql:host={$host};port={$port};dbname={$dbname};charset=utf8mb4";
    $pdo = new PDO($dsn, $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "Conexión exitosa\n\n";
    
    // Listar platillos
    $stmt = $pdo->prepare("SELECT ID_Menu, Platillo, Precio FROM menu LIMIT 5");
    $stmt->execute();
    $platillos = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "Platillos en BD:\n";
    print_r($platillos);
    echo "\n";
    
    // Intentar actualizar el primero
    if (!empty($platillos)) {
        $id = $platillos[0]['ID_Menu'];
        echo "Intentando actualizar platillo ID: $id\n";
        
        $stmt = $pdo->prepare("UPDATE menu SET Precio = ? WHERE ID_Menu = ?");
        $success = $stmt->execute(['999.99', $id]);
        
        if ($success) {
            echo "✓ UPDATE exitoso\n";
            echo "Filas afectadas: " . $stmt->rowCount() . "\n";
        } else {
            echo "✗ UPDATE falló\n";
        }
    }
    
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
?>
