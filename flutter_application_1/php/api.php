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
$host = 'mi-mysql-db.c6j6ewui4d46.us-east-1.rds.amazonaws.com';
$port = '3306';
$dbname = 'App1601';
$username = 'admin';
$password = 'JhairRios_2005';

try {
    // Conectar a la base de datos (incluye puerto y charset utf8mb4)
    $dsn = "mysql:host={$host};port={$port};dbname={$dbname};charset=utf8mb4";
    $pdo = new PDO($dsn, $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Aceptar sólo GET y POST
    if (!in_array($_SERVER['REQUEST_METHOD'], ['GET', 'POST'])) {
        echo json_encode(['success' => false, 'message' => 'Solo se permiten peticiones POST y GET']);
        exit;
    }

    // Leer datos
    $input_data = [];
    if ($_SERVER['REQUEST_METHOD'] == 'POST') {
        $content_type = $_SERVER['CONTENT_TYPE'] ?? '';
        if (strpos($content_type, 'application/json') !== false) {
            $json_data = json.decode(file_get_contents('php://input'), true);
            if ($json_data) $input_data = $json_data;
        } else {
            $input_data = $_POST;
        }
    } else {
        $input_data = $_GET;
    }

    // Leer action desde GET (query string) primero, luego desde input_data
    $action = $_GET['action'] ?? $input_data['action'] ?? null;

    // ----------------------- CATEGORIAS -----------------------
    if ($action === 'get_categorias') {
        try {
            $stmt = $pdo->prepare("SELECT ID_Categoria, Descripcion FROM categoria ORDER BY Descripcion");
            $stmt->execute();
            $categorias = $stmt->fetchAll(PDO::FETCH_ASSOC);
            echo json_encode(['success' => true, 'categorias' => $categorias]);
        } catch (PDOException $e) {
            echo json_encode(['success' => false, 'message' => 'Error obteniendo categorias: ' . $e->getMessage()]);
        }
        exit;
    }

    // ----------------------- ROLES -----------------------
    if ($action === 'get_roles') {
        try {
            $stmt = $pdo->prepare("SELECT Id_Rol, Descripcion FROM rol ORDER BY Descripcion");
            $stmt->execute();
            $roles = $stmt->fetchAll(PDO::FETCH_ASSOC);
            echo json_encode(['success' => true, 'roles' => $roles]);
        } catch (PDOException $e) {
            echo json_encode(['success' => false, 'message' => 'Error obteniendo roles: ' . $e->getMessage()]);
        }
        exit;
    }

    // ----------------------- USUARIOS -----------------------
    if ($action === 'create_user') {
        $nombre = $input_data['nombre'] ?? '';
        $correo = $input_data['correo'] ?? '';
        $telefono = $input_data['telefono'] ?? '';
        $contrasena = $input_data['contrasena'] ?? '';
        $id_rol = $input_data['id_rol'] ?? '';

        if (empty($nombre) || empty($correo) || empty($contrasena) || empty($id_rol)) {
            echo json_encode(['success' => false, 'message' => 'Todos los campos son requeridos excepto teléfono']);
            exit;
        }

        $stmt = $pdo->prepare("SELECT Id_Usuario FROM usuarios WHERE Correo = ?");
        $stmt->execute([$correo]);
        if ($stmt->fetch()) {
            echo json_encode(['success' => false, 'message' => 'El correo ya está registrado']);
            exit;
        }

        try {
            $stmt = $pdo->prepare("INSERT INTO usuarios (Nombre, Correo, Telefono, Contrasena, Fecha_Registro, Id_Rol, activo) VALUES (?, ?, ?, ?, NOW(), ?, 1)");
            $success = $stmt->execute([$nombre, $correo, $telefono, $contrasena, $id_rol]);
            if ($success) {
                echo json_encode(['success' => true, 'message' => 'Usuario creado exitosamente', 'user_id' => $pdo->lastInsertId()]);
            } else {
                echo json_encode(['success' => false, 'message' => 'Error al crear el usuario']);
            }
        } catch (PDOException $e) {
            echo json_encode(['success' => false, 'message' => 'Error creando usuario: ' . $e->getMessage()]);
        }
        exit;
    }

    if ($action === 'get_users') {
        try {
            $stmt = $pdo->prepare("SELECT u.Id_Usuario, u.Nombre, u.Correo, u.Telefono, u.Fecha_Registro, u.Id_Rol, u.activo, r.Descripcion FROM usuarios u LEFT JOIN rol r ON u.Id_Rol = r.Id_Rol ORDER BY u.Fecha_Registro DESC");
            $stmt->execute();
            $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
            echo json_encode(['success' => true, 'users' => $users]);
        } catch (PDOException $e) {
            echo json_encode(['success' => false, 'message' => 'Error obteniendo usuarios: ' . $e->getMessage()]);
        }
        exit;
    }

    if ($action === 'delete_user') {
        $id_usuario = $input_data['id_usuario'] ?? '';
        if (empty($id_usuario)) { echo json_encode(['success' => false, 'message' => 'ID de usuario requerido']); exit; }
        try {
            $stmt = $pdo->prepare("UPDATE usuarios SET activo = 0 WHERE Id_Usuario = ?");
            $success = $stmt->execute([$id_usuario]);
            if ($success && $stmt->rowCount() > 0) echo json_encode(['success' => true, 'message' => 'Usuario desactivado exitosamente']);
            else echo json_encode(['success' => false, 'message' => 'Usuario no encontrado']);
        } catch (PDOException $e) { echo json_encode(['success' => false, 'message' => 'Error eliminando usuario: ' . $e->getMessage()]); }
        exit;
    }

    if ($action === 'update_user') {
        $id_usuario = $input_data['id_usuario'] ?? '';
        $nombre = $input_data['nombre'] ?? '';
        $correo = $input_data['correo'] ?? '';
        $telefono = $input_data['telefono'] ?? '';
        $password = $input_data['password'] ?? '';
        $id_rol = $input_data['id_rol'] ?? '';
        $activo = $input_data['activo'] ?? 1;

        if (empty($id_usuario) || empty($nombre) || empty($correo) || empty($id_rol)) { echo json_encode(['success' => false, 'message' => 'Todos los campos son requeridos excepto teléfono y contraseña']); exit; }

        $stmt = $pdo->prepare("SELECT Id_Usuario FROM usuarios WHERE Correo = ? AND Id_Usuario != ?");
        $stmt->execute([$correo, $id_usuario]);
        if ($stmt->fetch()) { echo json_encode(['success' => false, 'message' => 'El correo ya está registrado por otro usuario']); exit; }

        try {
            if (!empty($password)) {
                $stmt = $pdo->prepare("UPDATE usuarios SET Nombre = ?, Correo = ?, Telefono = ?, Contrasena = ?, Id_Rol = ?, activo = ? WHERE Id_Usuario = ?");
                $success = $stmt->execute([$nombre, $correo, $telefono, $password, $id_rol, $activo, $id_usuario]);
            } else {
                $stmt = $pdo->prepare("UPDATE usuarios SET Nombre = ?, Correo = ?, Telefono = ?, Id_Rol = ?, activo = ? WHERE Id_Usuario = ?");
                $success = $stmt->execute([$nombre, $correo, $telefono, $id_rol, $activo, $id_usuario]);
            }
            if ($success && $stmt->rowCount() > 0) echo json_encode(['success' => true, 'message' => 'Usuario actualizado exitosamente']);
            else echo json_encode(['success' => false, 'message' => 'No se realizaron cambios o usuario no encontrado']);
        } catch (PDOException $e) { echo json_encode(['success' => false, 'message' => 'Error actualizando usuario: ' . $e->getMessage()]); }
        exit;
    }

    if ($action === 'toggle_user_status') {
        $id_usuario = $input_data['id_usuario'] ?? '';
        $activo = $input_data['activo'] ?? '';
        if (empty($id_usuario) || $activo === '') { echo json_encode(['success' => false, 'message' => 'ID de usuario y estado requeridos']); exit; }
        try {
            $stmt = $pdo->prepare("UPDATE usuarios SET activo = ? WHERE Id_Usuario = ?");
            $success = $stmt->execute([$activo, $id_usuario]);
            if ($success && $stmt->rowCount() > 0) {
                $mensaje = $activo == 1 ? 'Usuario activado exitosamente' : 'Usuario desactivado exitosamente';
                echo json_encode(['success' => true, 'message' => $mensaje]);
            } else echo json_encode(['success' => false, 'message' => 'Usuario no encontrado']);
        } catch (PDOException $e) { echo json_encode(['success' => false, 'message' => 'Error cambiando estado: ' . $e->getMessage()]); }
        exit;
    }

    if ($action === 'delete_user_permanently') {
        $id_usuario = $input_data['id_usuario'] ?? '';
        if (empty($id_usuario)) { echo json_encode(['success' => false, 'message' => 'ID de usuario requerido']); exit; }
        try {
            $stmt = $pdo->prepare("DELETE FROM usuarios WHERE Id_Usuario = ?");
            $success = $stmt->execute([$id_usuario]);
            if ($success && $stmt->rowCount() > 0) echo json_encode(['success' => true, 'message' => 'Usuario eliminado permanentemente']);
            else echo json_encode(['success' => false, 'message' => 'Usuario no encontrado']);
        } catch (PDOException $e) { echo json_encode(['success' => false, 'message' => 'Error eliminando usuario permanentemente: ' . $e->getMessage()]); }
        exit;
    }

    // ----------------------- REGISTRO -----------------------
    if ($action === 'register') {
        $nombre = $input_data['nombre'] ?? '';
        $email = $input_data['email'] ?? '';
        $password = $input_data['password'] ?? '';
        if (empty($nombre) || empty($email) || empty($password)) { echo json_encode(['success' => false, 'message' => 'Todos los campos son requeridos']); exit; }
        $stmt = $pdo->prepare("SELECT Id_Usuario FROM usuarios WHERE Correo = ?");
        $stmt->execute([$email]);
        if ($stmt->fetch()) { echo json_encode(['success' => false, 'message' => 'El email ya está registrado']); exit; }
        try {
            $stmt = $pdo->prepare("INSERT INTO usuarios (Nombre, Correo, Contrasena, activo, Id_Rol) VALUES (?, ?, ?, 1, 2)");
            $stmt->execute([$nombre, $email, $password]);
            $newUserId = $pdo->lastInsertId();
            echo json_encode(['success' => true, 'message' => 'Usuario registrado exitosamente', 'user' => ['id' => $newUserId, 'name' => $nombre, 'email' => $email, 'role_id' => 2]]);
        } catch (PDOException $e) { echo json_encode(['success' => false, 'message' => 'Error al registrar: ' . $e->getMessage()]); }
        exit;
    }

    // ----------------------- RECUPERAR CONTRASEÑA -----------------------
    if ($action === 'recover_password') {
        $email = $input_data['email'] ?? '';
        if (empty($email)) { echo json_encode(['success' => false, 'message' => 'Correo electrónico requerido']); exit; }
        try {
            $stmt = $pdo->prepare("SELECT Id_Usuario, Nombre FROM usuarios WHERE Correo = ? AND activo = 1");
            $stmt->execute([$email]);
            $user = $stmt->fetch();
            if (!$user) { echo json_encode(['success' => false, 'message' => 'No se encontró una cuenta activa con este correo electrónico']); exit; }
            $newPassword = substr(str_shuffle('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'), 0, 8);
            $updateStmt = $pdo->prepare("UPDATE usuarios SET Contrasena = ? WHERE Id_Usuario = ?");
            $success = $updateStmt->execute([$newPassword, $user['Id_Usuario']]);
            if ($success) echo json_encode(['success' => true, 'message' => "Nueva contraseña temporal generada para {$user['Nombre']}: $newPassword", 'new_password' => $newPassword, 'usuario' => $user['Nombre']]);
            else echo json_encode(['success' => false, 'message' => 'Error al actualizar la contraseña']);
        } catch (PDOException $e) { echo json_encode(['success' => false, 'message' => 'Error procesando solicitud: ' . $e->getMessage()]); }
        exit;
    }

    // ----------------------- CRUD RESTAURANTE -----------------------
    if ($action === 'get_restaurantes') {
        try {
            $stmt = $pdo->prepare("SELECT Restaurante_ID, Nombre, Logo, Direccion, Telefono, Correo FROM restaurante ORDER BY Nombre");
            $stmt->execute();
            $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
            echo json_encode(['success' => true, 'restaurantes' => $rows]);
        } catch (PDOException $e) { echo json_encode(['success' => false, 'message' => 'Error obteniendo restaurantes: ' . $e->getMessage()]); }
        exit;
    }

    if ($action === 'get_restaurante') {
        $id = $input_data['id'] ?? '';
        // Permitir ID = 0; validar solo si está ausente
        if ($id === '' || $id === null) { echo json_encode(['success' => false, 'message' => 'ID requerido']); exit; }
        try {
            $stmt = $pdo->prepare("SELECT Restaurante_ID, Nombre, Logo, Direccion, Telefono, Correo FROM restaurante WHERE Restaurante_ID = ?");
            $stmt->execute([$id]);
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            if ($row) echo json_encode(['success' => true, 'restaurante' => $row]);
            else echo json_encode(['success' => false, 'message' => 'Restaurante no encontrado']);
        } catch (PDOException $e) { echo json_encode(['success' => false, 'message' => 'Error obteniendo restaurante: ' . $e->getMessage()]); }
        exit;
    }

    if ($action === 'create_restaurante') {
        $nombre = $input_data['nombre'] ?? '';
        $logo = $input_data['logo'] ?? '';
        $direccion = $input_data['direccion'] ?? '';
        $telefono = $input_data['telefono'] ?? '';
        $correo = $input_data['correo'] ?? '';
        if (empty($nombre)) { echo json_encode(['success' => false, 'message' => 'Nombre requerido']); exit; }
        try {
            // Manejar upload de logo (campo multipart 'logo_file')
            if (isset($_FILES['logo_file']) && $_FILES['logo_file']['error'] === UPLOAD_ERR_OK) {
                $uploadDir = __DIR__ . '/uploads';
                if (!is_dir($uploadDir)) mkdir($uploadDir, 0755, true);
                $tmpName = $_FILES['logo_file']['tmp_name'];
                $origName = basename($_FILES['logo_file']['name']);
                $ext = pathinfo($origName, PATHINFO_EXTENSION);
                $newName = 'logo_' . time() . '.' . $ext;
                $dest = $uploadDir . '/' . $newName;
                if (move_uploaded_file($tmpName, $dest)) {
                    // Ruta accesible desde web (ajusta si tu virtual host es diferente)
                    $logo = '/Aplicacion_1/APP1601/APP_1601/flutter_application_1/php/uploads/' . $newName;
                }
            }
            $stmt = $pdo->prepare("INSERT INTO restaurante (Nombre, Logo, Direccion, Telefono, Correo) VALUES (?, ?, ?, ?, ?)");
            $success = $stmt->execute([$nombre, $logo, $direccion, $telefono, $correo]);
            if ($success) echo json_encode(['success' => true, 'message' => 'Restaurante creado', 'id' => $pdo->lastInsertId()]);
            else echo json_encode(['success' => false, 'message' => 'Error creando restaurante']);
        } catch (PDOException $e) { echo json_encode(['success' => false, 'message' => 'Error creando restaurante: ' . $e->getMessage()]); }
        exit;
    }

    if ($action === 'update_restaurante') {
        $id = $input_data['id'] ?? '';
        $nombre = $input_data['nombre'] ?? '';
        $logo = $input_data['logo'] ?? '';
        $direccion = $input_data['direccion'] ?? '';
        $telefono = $input_data['telefono'] ?? '';
        $correo = $input_data['correo'] ?? '';
        // Permitir ID = 0; comprobar explícitamente ausencia de id y nombre vacío
        if (($id === '' || $id === null) || trim($nombre) === '') { echo json_encode(['success' => false, 'message' => 'ID y Nombre requeridos']); exit; }
        try {
            // Comprobar que el restaurante existe
            $check = $pdo->prepare("SELECT Restaurante_ID FROM restaurante WHERE Restaurante_ID = ? LIMIT 1");
            $check->execute([$id]);
            $exists = $check->fetch(PDO::FETCH_ASSOC);
            if (!$exists) { echo json_encode(['success' => false, 'message' => 'Restaurante no encontrado']); exit; }
            // Si se envía archivo multipart 'logo_file', guardarlo y usar su ruta
            if (isset($_FILES['logo_file']) && $_FILES['logo_file']['error'] === UPLOAD_ERR_OK) {
                $uploadDir = __DIR__ . '/uploads';
                if (!is_dir($uploadDir)) mkdir($uploadDir, 0755, true);
                $tmpName = $_FILES['logo_file']['tmp_name'];
                $origName = basename($_FILES['logo_file']['name']);
                $ext = pathinfo($origName, PATHINFO_EXTENSION);
                $newName = 'logo_' . time() . '.' . $ext;
                $dest = $uploadDir . '/' . $newName;
                if (move_uploaded_file($tmpName, $dest)) {
                    $logo = '/Aplicacion_1/APP1601/APP_1601/flutter_application_1/php/uploads/' . $newName;
                }
            }
            $stmt = $pdo->prepare("UPDATE restaurante SET Nombre = ?, Logo = ?, Direccion = ?, Telefono = ?, Correo = ? WHERE Restaurante_ID = ?");
            $success = $stmt->execute([$nombre, $logo, $direccion, $telefono, $correo, $id]);
            if ($success) {
                // Si la ejecución fue exitosa devolvemos success=true (aunque rowCount==0 significa que los valores no cambiaron)
                echo json_encode(['success' => true, 'message' => 'Restaurante actualizado']);
            } else {
                echo json_encode(['success' => false, 'message' => 'Error actualizando restaurante']);
            }
        } catch (PDOException $e) { echo json_encode(['success' => false, 'message' => 'Error actualizando restaurante: ' . $e->getMessage()]); }
        exit;
    }

    if ($action === 'delete_restaurante') {
        $id = $input_data['id'] ?? '';
        if ($id === '' || $id === null) { echo json_encode(['success' => false, 'message' => 'ID requerido']); exit; }
        try {
            $stmt = $pdo->prepare("DELETE FROM restaurante WHERE Restaurante_ID = ?");
            $success = $stmt->execute([$id]);
            if ($success && $stmt->rowCount() > 0) echo json_encode(['success' => true, 'message' => 'Restaurante eliminado']);
            else echo json_encode(['success' => false, 'message' => 'Restaurante no encontrado']);
        } catch (PDOException $e) { echo json_encode(['success' => false, 'message' => 'Error eliminando restaurante: ' . $e->getMessage()]); }
        exit;
    }

    // ----------------------- LOGIN TRADICIONAL -----------------------
    if ($action === 'login' || $action === null) {
        $email = $input_data['email'] ?? '';
        $password = $input_data['password'] ?? '';
        if (empty($email) || empty($password)) { echo json_encode(['success' => false, 'message' => 'Email y contraseña requeridos']); exit; }
        $stmt = $pdo->prepare("SELECT * FROM usuarios WHERE Correo = ? AND (Contrasena = ? OR Contrasena = ?) AND activo = 1");
        $stmt->execute([$email, $password, md5($password)]);
        $user = $stmt->fetch();
        if ($user) {
            if ($user['Contrasena'] === md5($password) && $user['Contrasena'] !== $password) {
                $updateStmt = $pdo->prepare("UPDATE usuarios SET Contrasena = ? WHERE Id_Usuario = ?");
                $updateStmt->execute([$password, $user['Id_Usuario']]);
            }
            echo json_encode(['success' => true, 'message' => 'Login exitoso', 'user' => ['id' => $user['Id_Usuario'], 'name' => $user['Nombre'], 'email' => $user['Correo'], 'role_id' => $user['Id_Rol'], 'phone' => $user['Telefono']]]);
        } else {
            echo json_encode(['success' => false, 'message' => 'Credenciales incorrectas o usuario inactivo']);
        }
        exit;
    }

    if ($action === 'get_menu') {
        try {
            error_log('Acción detectada: get_menu');
            $stmt = $pdo->prepare("SELECT m.ID_Menu, m.Platillo, m.Precio, m.Descripcion, m.ID_Categoria, c.Descripcion AS CategoriaDescripcion, m.ID_Estado, m.Imagen FROM menu m JOIN categoria c ON m.ID_Categoria = c.ID_Categoria ORDER BY m.ID_Menu");
            $stmt->execute();
            $menu_items = $stmt->fetchAll(PDO::FETCH_ASSOC);
            error_log('Consulta ejecutada correctamente');
            echo json_encode(['success' => true, 'menu' => $menu_items]);
        } catch (PDOException $e) {
            error_log('Error en la consulta SQL: ' . $e->getMessage());
            echo json_encode(['success' => false, 'message' => 'Error obteniendo el menú: ' . $e->getMessage()]);
        }
        exit;
    }

    // ----------------------- AGREGAR MENU ITEM -----------------------
    if ($action === 'add_menu_item') {
        error_log('=== ADD_MENU_ITEM ===');
        error_log('Input data: ' . print_r($input_data, true));
        
        $platillo = $input_data['Platillo'] ?? '';
        $precio = $input_data['Precio'] ?? '';
        $descripcion = $input_data['Descripcion'] ?? '';
        $imagen = $input_data['Imagen'] ?? '';
        $id_categoria = $input_data['ID_Categoria'] ?? 1; // Por defecto categoría 1
        $id_estado = $input_data['ID_Estado'] ?? 2; // Por defecto estado 2 (Disponible)

        error_log("Platillo: $platillo, Precio: $precio, Categoria: $id_categoria, Estado: $id_estado");

        // Validar campos requeridos
        if (trim($platillo) === '' || trim($precio) === '') {
            error_log('Error: Platillo o precio vacíos');
            error_log("Platillo: '$platillo', Precio: '$precio'");
            echo json_encode(['success' => false, 'message' => 'Platillo y precio son requeridos']);
            exit;
        }

        try {
            // Manejar upload de imagen (campo multipart 'imagen_file')
            if (isset($_FILES['imagen_file']) && $_FILES['imagen_file']['error'] === UPLOAD_ERR_OK) {
                $uploadDir = __DIR__ . '/uploads';
                if (!is_dir($uploadDir)) mkdir($uploadDir, 0755, true);
                $tmpName = $_FILES['imagen_file']['tmp_name'];
                $origName = basename($_FILES['imagen_file']['name']);
                $ext = pathinfo($origName, PATHINFO_EXTENSION);
                $newName = 'platillo_' . time() . '_' . uniqid() . '.' . $ext;
                $dest = $uploadDir . '/' . $newName;
                if (move_uploaded_file($tmpName, $dest)) {
                    $imagen = '/Aplicacion_1/APP1601/APP_1601/flutter_application_1/php/uploads/' . $newName;
                }
            }

            $stmt = $pdo->prepare("INSERT INTO menu (Platillo, Precio, Descripcion, ID_Categoria, ID_Estado, Imagen) VALUES (?, ?, ?, ?, ?, ?)");
            $success = $stmt->execute([$platillo, $precio, $descripcion, $id_categoria, $id_estado, $imagen]);
            
            if ($success) {
                echo json_encode(['success' => true, 'message' => 'Platillo agregado exitosamente', 'id' => $pdo->lastInsertId()]);
            } else {
                echo json_encode(['success' => false, 'message' => 'Error al agregar el platillo']);
            }
        } catch (PDOException $e) {
            echo json_encode(['success' => false, 'message' => 'Error agregando platillo: ' . $e->getMessage()]);
        }
        exit;
    }

    // ----------------------- ACTUALIZAR MENU ITEM -----------------------
    if ($action === 'update_menu_item') {
        error_log('=== UPDATE_MENU_ITEM ===');
        error_log('Input data: ' . print_r($input_data, true));
        
        $id_menu = $input_data['ID_Menu'] ?? '';
        $platillo = $input_data['Platillo'] ?? '';
        $precio = $input_data['Precio'] ?? '';
        $descripcion = $input_data['Descripcion'] ?? '';
        $imagen = $input_data['Imagen'] ?? '';
        $id_categoria = $input_data['ID_Categoria'] ?? null;
        $id_estado = $input_data['ID_Estado'] ?? null;

        error_log("ID: $id_menu, Platillo: $platillo, Precio: $precio, Categoria: $id_categoria, Estado: $id_estado");

        // Validar campos requeridos (permitir 0 como valor válido)
        if ($id_menu === '' || $id_menu === null || trim($platillo) === '' || trim($precio) === '') {
            error_log('Error: ID, Platillo o precio vacíos');
            error_log("ID_Menu: '$id_menu', Platillo: '$platillo', Precio: '$precio'");
            echo json_encode(['success' => false, 'message' => 'ID, Platillo y precio son requeridos']);
            exit;
        }

        try {
            // Verificar que el platillo existe y obtener su imagen actual
            $check = $pdo->prepare("SELECT ID_Menu, ID_Categoria, ID_Estado, Imagen FROM menu WHERE ID_Menu = ?");
            $check->execute([$id_menu]);
            $exists = $check->fetch(PDO::FETCH_ASSOC);
            
            if (!$exists) {
                error_log('Error: Platillo no encontrado');
                echo json_encode(['success' => false, 'message' => 'Platillo no encontrado']);
                exit;
            }

            // Usar valores existentes si no se proporcionan nuevos
            if ($id_categoria === null || $id_categoria === '') $id_categoria = $exists['ID_Categoria'];
            if ($id_estado === null || $id_estado === '') $id_estado = $exists['ID_Estado'];
            
            // Si no hay imagen nueva, mantener la existente
            if (empty($imagen)) {
                $imagen = $exists['Imagen'];
            }

            // Manejar upload de imagen (campo multipart 'imagen_file')
            if (isset($_FILES['imagen_file']) && $_FILES['imagen_file']['error'] === UPLOAD_ERR_OK) {
                $uploadDir = __DIR__ . '/uploads';
                if (!is_dir($uploadDir)) mkdir($uploadDir, 0755, true);
                $tmpName = $_FILES['imagen_file']['tmp_name'];
                $origName = basename($_FILES['imagen_file']['name']);
                $ext = pathinfo($origName, PATHINFO_EXTENSION);
                $newName = 'platillo_' . time() . '_' . uniqid() . '.' . $ext;
                $dest = $uploadDir . '/' . $newName;
                if (move_uploaded_file($tmpName, $dest)) {
                    $imagen = '/Aplicacion_1/APP1601/APP_1601/flutter_application_1/php/uploads/' . $newName;
                }
            }

            error_log("Actualizando: Platillo=$platillo, Precio=$precio, Categoria=$id_categoria, Estado=$id_estado, Imagen=$imagen");

            $stmt = $pdo->prepare("UPDATE menu SET Platillo = ?, Precio = ?, Descripcion = ?, ID_Categoria = ?, ID_Estado = ?, Imagen = ? WHERE ID_Menu = ?");
            $success = $stmt->execute([$platillo, $precio, $descripcion, $id_categoria, $id_estado, $imagen, $id_menu]);
            
            if ($success) {
                error_log('✓ Platillo actualizado exitosamente');
                echo json_encode(['success' => true, 'message' => 'Platillo actualizado exitosamente']);
            } else {
                error_log('✗ Error al ejecutar UPDATE');
                echo json_encode(['success' => false, 'message' => 'Error al actualizar el platillo']);
            }
        } catch (PDOException $e) {
            error_log('✗ Exception PDO: ' . $e->getMessage());
            echo json_encode(['success' => false, 'message' => 'Error actualizando platillo: ' . $e->getMessage()]);
        }
        exit;
    }

    // ----------------------- ELIMINAR MENU ITEM -----------------------
    if ($action === 'delete_menu_item') {
        error_log('=== DELETE_MENU_ITEM ===');
        error_log('Input data: ' . print_r($input_data, true));
        
        $id_menu = $input_data['ID_Menu'] ?? '';
        
        error_log("ID a eliminar: $id_menu");

        // Validar ID (permitir 0 como valor válido)
        if ($id_menu === '' || $id_menu === null) {
            error_log('Error: ID vacío');
            error_log("ID_Menu recibido: '$id_menu'");
            echo json_encode(['success' => false, 'message' => 'ID del platillo requerido']);
            exit;
        }

        try {
            $stmt = $pdo->prepare("DELETE FROM menu WHERE ID_Menu = ?");
            $success = $stmt->execute([$id_menu]);
            
            if ($success && $stmt->rowCount() > 0) {
                echo json_encode(['success' => true, 'message' => 'Platillo eliminado exitosamente']);
            } else {
                echo json_encode(['success' => false, 'message' => 'Platillo no encontrado']);
            }
        } catch (PDOException $e) {
            echo json_encode(['success' => false, 'message' => 'Error eliminando platillo: ' . $e->getMessage()]);
        }
        exit;
    }

    // Si ninguna acción coincide
    echo json_encode(['success' => false, 'message' => 'Acción no reconocida']);

} catch (PDOException $e) {
    echo json_encode(['success' => false, 'message' => 'Error de conexión: ' . $e->getMessage()]);
}

?>