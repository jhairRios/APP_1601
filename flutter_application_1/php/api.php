<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Manejar peticiones OPTIONS (preflight)
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Configuración de la base de datos
$host = 'localhost';
$dbname = 'app1601';
$username = 'root';
$password = '';

try {
    // Conectar a la base de datos
    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Solo procesar peticiones POST y GET
    if ($_SERVER['REQUEST_METHOD'] == 'POST' || $_SERVER['REQUEST_METHOD'] == 'GET') {
        
        // Leer datos JSON si se envían como JSON
        $input_data = [];
        if ($_SERVER['REQUEST_METHOD'] == 'POST') {
            $content_type = $_SERVER['CONTENT_TYPE'] ?? '';
            if (strpos($content_type, 'application/json') !== false) {
                $json_data = json_decode(file_get_contents('php://input'), true);
                if ($json_data) {
                    $input_data = $json_data;
                }
            } else {
                $input_data = $_POST;
            }
        } else {
            $input_data = $_GET;
        }
        
        // Obtener acción del POST, GET o JSON
        $action = $input_data['action'] ?? $_POST['action'] ?? $_GET['action'] ?? 'login';
        
        // ========== OBTENER ROLES DE LA TABLA ROL ==========
        if ($action === 'get_roles') {
            try {
                $stmt = $pdo->prepare("SELECT Id_Rol, Descripcion FROM rol ORDER BY Descripcion");
                $stmt->execute();
                $roles = $stmt->fetchAll(PDO::FETCH_ASSOC);
                
                echo json_encode([
                    'success' => true,
                    'roles' => $roles
                ]);
                exit;
            } catch (PDOException $e) {
                echo json_encode([
                    'success' => false,
                    'message' => 'Error obteniendo roles: ' . $e->getMessage()
                ]);
                exit;
            }
        }
        
        // ========== CREAR NUEVO USUARIO ==========
        if ($action === 'create_user') {
            $nombre = $input_data['nombre'] ?? '';
            $correo = $input_data['correo'] ?? '';
            $telefono = $input_data['telefono'] ?? '';
            $contrasena = $input_data['contrasena'] ?? '';
            $id_rol = $input_data['id_rol'] ?? '';
            
            // Validar campos requeridos
            if (empty($nombre) || empty($correo) || empty($contrasena) || empty($id_rol)) {
                echo json_encode([
                    'success' => false,
                    'message' => 'Todos los campos son requeridos excepto teléfono'
                ]);
                exit;
            }
            
            // Verificar que el correo no esté ya registrado
            $stmt = $pdo->prepare("SELECT Id_Usuario FROM usuarios WHERE Correo = ?");
            $stmt->execute([$correo]);
            if ($stmt->fetch()) {
                echo json_encode([
                    'success' => false,
                    'message' => 'El correo ya está registrado'
                ]);
                exit;
            }
            
            try {
                // Insertar nuevo usuario
                $stmt = $pdo->prepare("INSERT INTO usuarios (Nombre, Correo, Telefono, Contrasena, Fecha_Registro, Id_Rol, activo) VALUES (?, ?, ?, ?, NOW(), ?, 1)");
                $success = $stmt->execute([
                    $nombre,
                    $correo,
                    $telefono,
                    $contrasena, // ✅ SIN ENCRIPTACIÓN: Contraseña en texto plano
                    $id_rol
                ]);
                
                if ($success) {
                    echo json_encode([
                        'success' => true,
                        'message' => 'Usuario creado exitosamente',
                        'user_id' => $pdo->lastInsertId()
                    ]);
                } else {
                    echo json_encode([
                        'success' => false,
                        'message' => 'Error al crear el usuario'
                    ]);
                }
                exit;
            } catch (PDOException $e) {
                echo json_encode([
                    'success' => false,
                    'message' => 'Error creando usuario: ' . $e->getMessage()
                ]);
                exit;
            }
        }
        
        // ========== OBTENER USUARIOS ==========
        if ($action === 'get_users') {
            try {
                $stmt = $pdo->prepare("
                    SELECT u.Id_Usuario, u.Nombre, u.Correo, u.Telefono, u.Fecha_Registro, 
                        u.Id_Rol, u.activo, r.Descripcion
                    FROM usuarios u 
                    LEFT JOIN rol r ON u.Id_Rol = r.Id_Rol 
                    ORDER BY u.Fecha_Registro DESC
                ");
                $stmt->execute();
                $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
                
                echo json_encode([
                    'success' => true,
                    'users' => $users
                ]);
                exit;
            } catch (PDOException $e) {
                echo json_encode([
                    'success' => false,
                    'message' => 'Error obteniendo usuarios: ' . $e->getMessage()
                ]);
                exit;
            }
        }
        
        // ========== ELIMINAR USUARIO ==========
        if ($action === 'delete_user') {
            $id_usuario = $input_data['id_usuario'] ?? '';
            
            if (empty($id_usuario)) {
                echo json_encode([
                    'success' => false,
                    'message' => 'ID de usuario requerido'
                ]);
                exit;
            }
            
            try {
                // Soft delete - marcar como inactivo
                $stmt = $pdo->prepare("UPDATE usuarios SET activo = 0 WHERE Id_Usuario = ?");
                $success = $stmt->execute([$id_usuario]);
                
                if ($success && $stmt->rowCount() > 0) {
                    echo json_encode([
                        'success' => true,
                        'message' => 'Usuario desactivado exitosamente'
                    ]);
                } else {
                    echo json_encode([
                        'success' => false,
                        'message' => 'Usuario no encontrado'
                    ]);
                }
                exit;
            } catch (PDOException $e) {
                echo json_encode([
                    'success' => false,
                    'message' => 'Error eliminando usuario: ' . $e->getMessage()
                ]);
                exit;
            }
        }

        // ========== ACTUALIZAR USUARIO ==========
        if ($action === 'update_user') {
            $id_usuario = $input_data['id_usuario'] ?? '';
            $nombre = $input_data['nombre'] ?? '';
            $correo = $input_data['correo'] ?? '';
            $telefono = $input_data['telefono'] ?? '';
            $password = $input_data['password'] ?? '';
            $id_rol = $input_data['id_rol'] ?? '';
            $activo = $input_data['activo'] ?? 1;
            
            if (empty($id_usuario) || empty($nombre) || empty($correo) || empty($id_rol)) {
                echo json_encode([
                    'success' => false,
                    'message' => 'Todos los campos son requeridos excepto teléfono y contraseña'
                ]);
                exit;
            }
            
            // Verificar que el correo no esté ya registrado por otro usuario
            $stmt = $pdo->prepare("SELECT Id_Usuario FROM usuarios WHERE Correo = ? AND Id_Usuario != ?");
            $stmt->execute([$correo, $id_usuario]);
            if ($stmt->fetch()) {
                echo json_encode([
                    'success' => false,
                    'message' => 'El correo ya está registrado por otro usuario'
                ]);
                exit;
            }
            
            try {
                // Actualizar usuario (con o sin contraseña)
                if (!empty($password)) {
                    // Actualizar con nueva contraseña
                    $stmt = $pdo->prepare("UPDATE usuarios SET Nombre = ?, Correo = ?, Telefono = ?, Contrasena = ?, Id_Rol = ?, activo = ? WHERE Id_Usuario = ?");
                    $success = $stmt->execute([
                        $nombre,
                        $correo,
                        $telefono,
                        $password, // ✅ SIN ENCRIPTACIÓN: Contraseña en texto plano
                        $id_rol,
                        $activo,
                        $id_usuario
                    ]);
                } else {
                    // Actualizar sin cambiar contraseña
                    $stmt = $pdo->prepare("UPDATE usuarios SET Nombre = ?, Correo = ?, Telefono = ?, Id_Rol = ?, activo = ? WHERE Id_Usuario = ?");
                    $success = $stmt->execute([
                        $nombre,
                        $correo,
                        $telefono,
                        $id_rol,
                        $activo,
                        $id_usuario
                    ]);
                }
                
                if ($success && $stmt->rowCount() > 0) {
                    echo json_encode([
                        'success' => true,
                        'message' => 'Usuario actualizado exitosamente'
                    ]);
                } else {
                    echo json_encode([
                        'success' => false,
                        'message' => 'No se realizaron cambios o usuario no encontrado'
                    ]);
                }
                exit;
            } catch (PDOException $e) {
                echo json_encode([
                    'success' => false,
                    'message' => 'Error actualizando usuario: ' . $e->getMessage()
                ]);
                exit;
            }
        }

        // ========== CAMBIAR ESTADO USUARIO ==========
        if ($action === 'toggle_user_status') {
            $id_usuario = $input_data['id_usuario'] ?? '';
            $activo = $input_data['activo'] ?? '';
            
            if (empty($id_usuario) || $activo === '') {
                echo json_encode([
                    'success' => false,
                    'message' => 'ID de usuario y estado requeridos'
                ]);
                exit;
            }
            
            try {
                $stmt = $pdo->prepare("UPDATE usuarios SET activo = ? WHERE Id_Usuario = ?");
                $success = $stmt->execute([$activo, $id_usuario]);
                
                if ($success && $stmt->rowCount() > 0) {
                    $mensaje = $activo == 1 ? 'Usuario activado exitosamente' : 'Usuario desactivado exitosamente';
                    echo json_encode([
                        'success' => true,
                        'message' => $mensaje
                    ]);
                } else {
                    echo json_encode([
                        'success' => false,
                        'message' => 'Usuario no encontrado'
                    ]);
                }
                exit;
            } catch (PDOException $e) {
                echo json_encode([
                    'success' => false,
                    'message' => 'Error cambiando estado: ' . $e->getMessage()
                ]);
                exit;
            }
        }

        // ========== ELIMINAR USUARIO DEFINITIVAMENTE ==========
        if ($action === 'delete_user_permanently') {
            $id_usuario = $input_data['id_usuario'] ?? '';
            
            if (empty($id_usuario)) {
                echo json_encode([
                    'success' => false,
                    'message' => 'ID de usuario requerido'
                ]);
                exit;
            }
            
            try {
                // Hard delete - eliminar permanentemente
                $stmt = $pdo->prepare("DELETE FROM usuarios WHERE Id_Usuario = ?");
                $success = $stmt->execute([$id_usuario]);
                
                if ($success && $stmt->rowCount() > 0) {
                    echo json_encode([
                        'success' => true,
                        'message' => 'Usuario eliminado permanentemente'
                    ]);
                } else {
                    echo json_encode([
                        'success' => false,
                        'message' => 'Usuario no encontrado'
                    ]);
                }
                exit;
            } catch (PDOException $e) {
                echo json_encode([
                    'success' => false,
                    'message' => 'Error eliminando usuario permanentemente: ' . $e->getMessage()
                ]);
                exit;
            }
        }
        
        // ========== NUEVA FUNCIONALIDAD: REGISTRO DE USUARIO ==========
        if ($action === 'register') {
            // Obtener datos del formulario
            $nombre = $input_data['nombre'] ?? '';
            $email = $input_data['email'] ?? '';
            $password = $input_data['password'] ?? '';
            
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
                $stmt->execute([$nombre, $email, $password]); // ✅ SIN ENCRIPTACIÓN: Contraseña en texto plano
                
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
        
        // ========== RECUPERAR CONTRASEÑA ==========
        if ($action === 'recover_password') {
            $email = $input_data['email'] ?? '';
            
            if (empty($email)) {
                echo json_encode(['success' => false, 'message' => 'Correo electrónico requerido']);
                exit;
            }
            
            try {
                // Verificar si el correo existe en la base de datos y está activo
                $stmt = $pdo->prepare("SELECT Id_Usuario, Nombre FROM usuarios WHERE Correo = ? AND activo = 1");
                $stmt->execute([$email]);
                $user = $stmt->fetch();
                
                if (!$user) {
                    echo json_encode(['success' => false, 'message' => 'No se encontró una cuenta activa con este correo electrónico']);
                    exit;
                }
                
                // Generar nueva contraseña temporal (8 caracteres alfanuméricos)
                $newPassword = substr(str_shuffle('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'), 0, 8);
                
                // Actualizar la contraseña en la base de datos
                // ✅ SIN ENCRIPTACIÓN: Guardar contraseña en texto plano
                $updateStmt = $pdo->prepare("UPDATE usuarios SET Contrasena = ? WHERE Id_Usuario = ?");
                $success = $updateStmt->execute([$newPassword, $user['Id_Usuario']]);
                
                if ($success) {
                    echo json_encode([
                        'success' => true, 
                        'message' => "Nueva contraseña temporal generada para {$user['Nombre']}: $newPassword",
                        'new_password' => $newPassword,
                        'usuario' => $user['Nombre']
                    ]);
                } else {
                    echo json_encode(['success' => false, 'message' => 'Error al actualizar la contraseña']);
                }
                exit;
                
            } catch (PDOException $e) {
                echo json_encode(['success' => false, 'message' => 'Error procesando solicitud: ' . $e->getMessage()]);
                exit;
            }
        }
        // ========== FIN RECUPERAR CONTRASEÑA ==========
        
        // Obtener datos del POST (login tradicional)
        $email = $input_data['email'] ?? '';
        $password = $input_data['password'] ?? '';
        
        // Validar que no estén vacíos
        if (empty($email) || empty($password)) {
            echo json_encode(['success' => false, 'message' => 'Email y contraseña requeridos']);
            exit;
        }
        
        // Buscar usuario en la base de datos
        // ✅ SISTEMA HÍBRIDO: Probar ambas versiones (texto plano y MD5)
        $stmt = $pdo->prepare("SELECT * FROM usuarios WHERE Correo = ? AND (Contrasena = ? OR Contrasena = ?) AND activo = 1");
        $stmt->execute([$email, $password, md5($password)]);
        $user = $stmt->fetch();
        
        if ($user) {
            // ✅ MIGRACIÓN AUTOMÁTICA: Si la contraseña actual es MD5, actualizarla a texto plano
            if ($user['Contrasena'] === md5($password) && $user['Contrasena'] !== $password) {
                $updateStmt = $pdo->prepare("UPDATE usuarios SET Contrasena = ? WHERE Id_Usuario = ?");
                $updateStmt->execute([$password, $user['Id_Usuario']]);
            }
            
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
        echo json_encode(['success' => false, 'message' => 'Solo se permiten peticiones POST y GET']);
    }
    
} catch (PDOException $e) {
    echo json_encode(['success' => false, 'message' => 'Error de conexión: ' . $e->getMessage()]);
}
?>