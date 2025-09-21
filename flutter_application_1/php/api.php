<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// Configuración de la base de datos
$host = 'localhost';
$dbname = 'app1601';
$username = 'root';
$password = '';

try {
    // Conectar a la base de datos
    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Solo procesar peticiones POST
    if ($_SERVER['REQUEST_METHOD'] == 'POST') {
        
        // Obtener datos del POST
        $email = $_POST['email'] ?? '';
        $password = $_POST['password'] ?? '';
        
        // Validar que no estén vacíos
        if (empty($email) || empty($password)) {
            echo json_encode(['success' => false, 'message' => 'Email y contraseña requeridos']);
            exit;
        }
        
        // Buscar usuario en la base de datos
        // ✅ ADAPTADO: Usar los nombres de campos de tu tabla usuarios
        $stmt = $pdo->prepare("SELECT * FROM usuarios WHERE Correo = ? AND Contrasena = ? AND activo = 1");
        $stmt->execute([$email, $password]);
        $user = $stmt->fetch();
        
        if ($user) {
            // Usuario encontrado y activo
            echo json_encode([
                'success' => true, 
                'message' => 'Login exitoso',
                'user' => [
                    'id' => $user['Id_Usuario'],        // ✅ Campo Id_Usuario
                    'name' => $user['Nombre'],          // ✅ Campo Nombre
                    'email' => $user['Correo'],         // ✅ Campo Correo
                    'role_id' => $user['Id_Rol'],       // ✅ Campo Id_Rol
                    'phone' => $user['Telefono']        // ✅ Campo Telefono (opcional)
                ]
            ]);
        } else {
            // Usuario no encontrado o inactivo
            echo json_encode(['success' => false, 'message' => 'Credenciales incorrectas o usuario inactivo']);
        }
        
    } else {
        echo json_encode(['success' => false, 'message' => 'Solo se permiten peticiones POST']);
    }
    
} catch (PDOException $e) {
    echo json_encode(['success' => false, 'message' => 'Error de conexión: ' . $e->getMessage()]);
}
?>