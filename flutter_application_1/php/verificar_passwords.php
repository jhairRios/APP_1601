<?php
// Script para verificar y corregir contraseñas
header('Content-Type: application/json');

$host = 'localhost';
$dbname = 'app1601';
$username = 'root';
$password = '';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Obtener todos los usuarios
    $stmt = $pdo->prepare("SELECT Id_Usuario, Nombre, Correo, Contrasena FROM usuarios");
    $stmt->execute();
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $results = [];
    $fixed_count = 0;
    
    foreach ($users as $user) {
        $password_hash = $user['Contrasena'];
        $is_md5 = (strlen($password_hash) == 32 && ctype_xdigit($password_hash));
        
        if (!$is_md5) {
            // La contraseña no está en MD5, corregirla
            $new_hash = md5($password_hash);
            
            $update_stmt = $pdo->prepare("UPDATE usuarios SET Contrasena = ? WHERE Id_Usuario = ?");
            $update_stmt->execute([$new_hash, $user['Id_Usuario']]);
            
            $fixed_count++;
            $results[] = [
                'id' => $user['Id_Usuario'],
                'nombre' => $user['Nombre'],
                'email' => $user['Correo'],
                'password_original' => $password_hash,
                'password_md5' => $new_hash,
                'status' => 'CORREGIDA'
            ];
        } else {
            $results[] = [
                'id' => $user['Id_Usuario'],
                'nombre' => $user['Nombre'],
                'email' => $user['Correo'],
                'password_md5' => $password_hash,
                'status' => 'YA_EN_MD5'
            ];
        }
    }
    
    echo json_encode([
        'success' => true,
        'message' => "Proceso completado. Se corrigieron $fixed_count contraseñas.",
        'total_users' => count($users),
        'fixed_passwords' => $fixed_count,
        'details' => $results
    ], JSON_PRETTY_PRINT);
    
} catch (PDOException $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage()
    ]);
}
?>