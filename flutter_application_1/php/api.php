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
        
        // Obtener acción del POST (para manejar diferentes tipos de login)
        $action = $_POST['action'] ?? 'login';
        
        // ========== NUEVA FUNCIONALIDAD: GOOGLE LOGIN ==========
        if ($action === 'google_login') {
            // Obtener datos del Google Sign-In
            $email = $_POST['email'] ?? '';
            $name = $_POST['name'] ?? '';
            
            // Validar que no estén vacíos
            if (empty($email) || empty($name)) {
                echo json_encode(['success' => false, 'message' => 'Email y nombre requeridos para Google Login']);
                exit;
            }
            
            // Verificar si el usuario ya existe
            $stmt = $pdo->prepare("SELECT * FROM usuarios WHERE Correo = ?");
            $stmt->execute([$email]);
            $existingUser = $stmt->fetch();
            
            if ($existingUser) {
                // Usuario ya existe, responder éxito
                echo json_encode([
                    'success' => true, 
                    'message' => 'Usuario ya registrado, login exitoso',
                    'user' => [
                        'id' => $existingUser['Id_Usuario'],
                        'name' => $existingUser['Nombre'],
                        'email' => $existingUser['Correo'],
                        'role_id' => $existingUser['Id_Rol']
                    ]
                ]);
            } else {
                // Usuario no existe, crear nuevo usuario
                try {
                    // Para usuarios de Google, usamos una contraseña especial
                    $googlePassword = 'GOOGLE_USER_' . md5($email);
                    $stmt = $pdo->prepare("INSERT INTO usuarios (Nombre, Correo, Contrasena, activo, Id_Rol) VALUES (?, ?, ?, 1, 2)");
                    $stmt->execute([$name, $email, $googlePassword]);
                    
                    // Obtener el ID del usuario recién creado
                    $newUserId = $pdo->lastInsertId();
                    
                    echo json_encode([
                        'success' => true, 
                        'message' => 'Usuario registrado y login exitoso',
                        'user' => [
                            'id' => $newUserId,
                            'name' => $name,
                            'email' => $email,
                            'role_id' => 2
                        ]
                    ]);
                } catch (PDOException $e) {
                    echo json_encode(['success' => false, 'message' => 'Error al registrar usuario: ' . $e->getMessage()]);
                }
            }
            exit;
        }
        // ========== FIN NUEVA FUNCIONALIDAD ==========
        
        // ========== NUEVA FUNCIONALIDAD: REGISTRO DE USUARIO ==========
        if ($action === 'register') {
            // Obtener datos del formulario
            $nombre = $_POST['nombre'] ?? '';
            $email = $_POST['email'] ?? '';
            $password = $_POST['password'] ?? '';
            
            // Validar que no estén vacíos
            if (empty($nombre) || empty($email) || empty($password)) {
                echo json_encode(['success' => false, 'message' => 'Todos los campos son requeridos']);
                exit;
            }
            
            // Verificar si el email ya existe
            $stmt = $pdo->prepare("SELECT Id_Usuario FROM usuarios WHERE Correo = ?");
            $stmt->execute([$email]);
            
            if ($stmt->fetch()) {
                echo json_encode(['success' => false, 'message' => 'El email ya está registrado']);
                exit;
            }
            
            // Crear nuevo usuario
            try {
                $stmt = $pdo->prepare("INSERT INTO usuarios (Nombre, Correo, Contrasena, activo, Id_Rol) VALUES (?, ?, ?, 1, 2)");
                $stmt->execute([$nombre, $email, $password]);
                
                $newUserId = $pdo->lastInsertId();
                
                echo json_encode([
                    'success' => true,
                    'message' => 'Usuario registrado exitosamente',
                    'user' => [
                        'id' => $newUserId,
                        'name' => $nombre,
                        'email' => $email,
                        'role_id' => 2
                    ]
                ]);
            } catch (PDOException $e) {
                echo json_encode(['success' => false, 'message' => 'Error al registrar: ' . $e->getMessage()]);
            }
            exit;
        }
        // ========== FIN REGISTRO ==========
        
        // Obtener datos del POST (login tradicional)
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