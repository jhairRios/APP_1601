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

// Admin key for sensitive operations (can be set via env API_ADMIN_KEY). Change before production.
$adminKeyEnv = getenv('API_ADMIN_KEY');
$ADMIN_DELETE_KEY = ($adminKeyEnv !== false && $adminKeyEnv !== null) ? $adminKeyEnv : 'please-set-admin-key';

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
        // Capturar el cuerpo crudo para debug y luego decodificar JSON si aplica
        $raw_body = file_get_contents('php://input');
        if (strpos($content_type, 'application/json') !== false) {
            $json_data = json_decode($raw_body, true);
            if ($json_data) $input_data = $json_data;
            else $input_data = [];
        } else {
            $input_data = $_POST;
        }
    } else {
        $input_data = $_GET;
    }

    // Determinar la acción: preferir el body (JSON o POST), si no está, tomar la query string (ej. multipart requests usan query)
    $action = $input_data['action'] ?? $_GET['action'] ?? $_REQUEST['action'] ?? null;

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

    // ----------------------- LISTAR REPARTIDORES (Top-level handler) -----------------------
    if ($action === 'get_repartidores') {
        try {
            // Determine repartidor column in pedidos if present to compute assigned counts
            $colsStmt = $pdo->prepare("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'pedidos'");
            $colsStmt->execute([$dbname]);
            $cols = $colsStmt->fetchAll(PDO::FETCH_COLUMN, 0);
            $repartidorCol = null; $estadoCol = null; $idCol = null;
            foreach ($cols as $c) {
                $low = strtolower($c);
                if (in_array($low, ['id_repartidor','idrepartidor','repartidor_id','id_repartidores'])) { $repartidorCol = $c; }
                if (in_array($low, ['estado','estado_pedido','status'])) { if ($estadoCol===null) $estadoCol = $c; }
                if (in_array($low, ['id_pedido','idpedidos','id','id_pedidos'])) { if ($idCol===null) $idCol = $c; }
            }
            if ($idCol === null && count($cols) > 0) $idCol = $cols[0];

            // Build query: return repartidor rows plus assigned_count (active orders)
            // Try to join usuarios to get display name when available
            $sql = "SELECT r.*, u.Nombre AS Nombre";
            if ($repartidorCol !== null) {
                $sql .= ", COUNT(p.{$repartidorCol}) AS assigned_count";
            } else {
                $sql .= ", 0 AS assigned_count";
            }
            $sql .= " FROM repartidor r LEFT JOIN usuarios u ON u.Id_Usuario = r.ID_Usuario";
            if ($repartidorCol !== null) {
                $estadoCond = ($estadoCol !== null) ? "AND (p.{$estadoCol} NOT IN ('Entregado','entregado','Cancelado','cancelado'))" : "";
                $sql .= " LEFT JOIN pedidos p ON p.{$repartidorCol} = r.ID_Repartidor {$estadoCond}";
                $sql .= " GROUP BY r.ID_Repartidor ORDER BY assigned_count ASC";
            }
            $stmt = $pdo->prepare($sql);
            $stmt->execute();
            $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
            echo json_encode(['success' => true, 'repartidores' => $rows]);
        } catch (PDOException $e) {
            echo json_encode(['success' => false, 'message' => 'Error obteniendo repartidores: ' . $e->getMessage()]);
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
            
            // ----------------------- LISTAR REPARTIDORES -----------------------
            if ($action === 'get_repartidores') {
                try {
                    // Determine repartidor column in pedidos if present to compute assigned counts
                    $colsStmt = $pdo->prepare("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'pedidos'");
                    $colsStmt->execute([$dbname]);
                    $cols = $colsStmt->fetchAll(PDO::FETCH_COLUMN, 0);
                    $repartidorCol = null; $estadoCol = null; $idCol = null;
                    foreach ($cols as $c) {
                        $low = strtolower($c);
                        if (in_array($low, ['id_repartidor','idrepartidor','repartidor_id','id_repartidores'])) { $repartidorCol = $c; }
                        if (in_array($low, ['estado','estado_pedido','status'])) { if ($estadoCol===null) $estadoCol = $c; }
                        if (in_array($low, ['id_pedido','idpedidos','id','id_pedidos'])) { if ($idCol===null) $idCol = $c; }
                    }
                    if ($idCol === null && count($cols) > 0) $idCol = $cols[0];

                    // Build query: return repartidor rows plus assigned_count (active orders)
                    // Try to join usuarios to get display name when available
                    $sql = "SELECT r.*, u.Nombre AS Nombre";
                    if ($repartidorCol !== null) {
                        $sql .= ", COUNT(p.{$repartidorCol}) AS assigned_count";
                    } else {
                        $sql .= ", 0 AS assigned_count";
                    }
                    $sql .= " FROM repartidor r LEFT JOIN usuarios u ON u.Id_Usuario = r.ID_Usuario";
                    if ($repartidorCol !== null) {
                        $estadoCond = ($estadoCol !== null) ? "AND (p.{$estadoCol} NOT IN ('Entregado','entregado','Cancelado','cancelado'))" : "";
                        $sql .= " LEFT JOIN pedidos p ON p.{$repartidorCol} = r.ID_Repartidor {$estadoCond}";
                        $sql .= " GROUP BY r.ID_Repartidor ORDER BY assigned_count ASC";
                    }
                    $stmt = $pdo->prepare($sql);
                    $stmt->execute();
                    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
                    echo json_encode(['success' => true, 'repartidores' => $rows]);
                } catch (PDOException $e) {
                    echo json_encode(['success' => false, 'message' => 'Error obteniendo repartidores: ' . $e->getMessage()]);
                }
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

    // ----------------------- CRUD MENU (ADD / UPDATE) -----------------------
    // Helper: sanitize platillo name to a safe filename (replace spaces, remove accents/chars)
    function sanitize_filename($name) {
        // Convertir a ASCII básico, eliminar acentos si está disponible iconv
        if (function_exists('iconv')) {
            $name = iconv('UTF-8', 'ASCII//TRANSLIT', $name);
        }
        // Reemplazar cualquier cosa que no sea letra/número por guion bajo
        $name = preg_replace('/[^A-Za-z0-9]+/', '_', $name);
        // Trimear guiones bajos repetidos y extremos
        $name = preg_replace('/_+/', '_', $name);
        $name = trim($name, '_');
        // Limitar tamaño
        return substr($name, 0, 120);
    }

    if ($action === 'add_menu_item') {
        $platillo = $input_data['Platillo'] ?? $input_data['platillo'] ?? '';
        $precio = $input_data['Precio'] ?? $input_data['precio'] ?? 0;
        $descripcion = $input_data['Descripcion'] ?? $input_data['descripcion'] ?? '';
        $id_categoria = $input_data['ID_Categoria'] ?? $input_data['id_categoria'] ?? 0;
        $id_estado = $input_data['ID_Estado'] ?? $input_data['id_estado'] ?? 1;
        $imagen = $input_data['Imagen'] ?? '';

        if (trim($platillo) === '') { echo json_encode(['success' => false, 'message' => 'Platillo requerido']); exit; }

        try {
            // Si se envía archivo multipart 'imagen_file', guardarlo dentro de assets/Menu
            if (isset($_FILES['imagen_file']) && $_FILES['imagen_file']['error'] === UPLOAD_ERR_OK) {
                $uploadDir = __DIR__ . '/../assets/Menu';
                if (!is_dir($uploadDir)) mkdir($uploadDir, 0755, true);
                $tmpName = $_FILES['imagen_file']['tmp_name'];
                $origName = basename($_FILES['imagen_file']['name']);
                $ext = strtolower(pathinfo($origName, PATHINFO_EXTENSION));
                if ($ext === '') $ext = 'jpg';
                $base = sanitize_filename($platillo);
                $newName = $base . '.' . $ext;
                $dest = $uploadDir . '/' . $newName;
                // Si ya existe un archivo con ese nombre, añadir timestamp para evitar sobrescribir accidentalmente
                // Para creación mantenemos comportamiento de evitar sobreescritura accidental añadiendo timestamp
                if (file_exists($dest)) {
                    $newName = $base . '_' . time() . '.' . $ext;
                    $dest = $uploadDir . '/' . $newName;
                }
                if (move_uploaded_file($tmpName, $dest)) {
                    // Guardamos sólo el nombre del archivo en la BD (ej. Coca_Cola.png)
                    $imagen = $newName;
                }
            }

            $stmt = $pdo->prepare("INSERT INTO menu (Platillo, Precio, Descripcion, ID_Categoria, ID_Estado, Imagen) VALUES (?, ?, ?, ?, ?, ?)");
            $success = $stmt->execute([$platillo, $precio, $descripcion, $id_categoria, $id_estado, $imagen]);
            if ($success) echo json_encode(['success' => true, 'message' => 'Platillo agregado', 'id' => $pdo->lastInsertId(), 'imagen' => $imagen]);
            else echo json_encode(['success' => false, 'message' => 'Error creando platillo']);
        } catch (PDOException $e) { echo json_encode(['success' => false, 'message' => 'Error creando platillo: ' . $e->getMessage()]); }
        exit;
    }

    if ($action === 'update_menu_item') {
        $id_menu = $input_data['ID_Menu'] ?? $input_data['id_menu'] ?? $input_data['ID'] ?? '';
        if ($id_menu === '' || $id_menu === null) { echo json_encode(['success' => false, 'message' => 'ID_Menu requerido']); exit; }

        // Campos nuevos (si vienen)
        $platillo = $input_data['Platillo'] ?? null;
        $precio = $input_data['Precio'] ?? null;
        $descripcion = $input_data['Descripcion'] ?? null;
        $id_categoria = $input_data['ID_Categoria'] ?? null;
        $id_estado = $input_data['ID_Estado'] ?? null;
        $imagen = $input_data['Imagen'] ?? null; // si viene, puede ser URL o nombre

        try {
            // Obtener registro actual
            $check = $pdo->prepare("SELECT Platillo, Imagen FROM menu WHERE ID_Menu = ? LIMIT 1");
            $check->execute([$id_menu]);
            $row = $check->fetch(PDO::FETCH_ASSOC);
            if (!$row) { echo json_encode(['success' => false, 'message' => 'Platillo no encontrado']); exit; }

            $oldPlatillo = $row['Platillo'];
            $oldImagen = $row['Imagen'];

            $newPlatillo = $platillo !== null ? $platillo : $oldPlatillo;
            $newImagen = $imagen !== null ? $imagen : $oldImagen;

            $assetsDir = __DIR__ . '/../assets/Menu';
            if (!is_dir($assetsDir)) mkdir($assetsDir, 0755, true);

            // Si llega un nuevo archivo multipart, guardarlo con el nombre del platillo nuevo
            if (isset($_FILES['imagen_file']) && $_FILES['imagen_file']['error'] === UPLOAD_ERR_OK) {
                $tmpName = $_FILES['imagen_file']['tmp_name'];
                $origName = basename($_FILES['imagen_file']['name']);
                $ext = strtolower(pathinfo($origName, PATHINFO_EXTENSION));
                if ($ext === '') $ext = 'jpg';
                $base = sanitize_filename($newPlatillo);
                $newName = $base . '.' . $ext;
                $dest = $assetsDir . '/' . $newName;
                // Si el destino ya existe, en actualización queremos REEMPLAZARla para evitar archivos duplicados
                if (file_exists($dest)) {
                    // Intentar borrar el destino antes de mover (silenciar errores)
                    @unlink($dest);
                }
                if (move_uploaded_file($tmpName, $dest)) {
                    // Eliminar imagen vieja si estaba en assets (y difiere del destino)
                    if (!empty($oldImagen) && strpos($oldImagen, '/') === false) {
                        $oldPath = $assetsDir . '/' . $oldImagen;
                        if (file_exists($oldPath) && $oldPath !== $dest) @unlink($oldPath);
                    }
                    $newImagen = $newName;
                }
            } else {
                // No se envió nuevo archivo, pero si cambió el nombre del platillo y existe imagen local, renombrarla
                if ($platillo !== null && !empty($oldImagen) && strpos($oldImagen, '/') === false) {
                    $oldPath = $assetsDir . '/' . $oldImagen;
                    if (file_exists($oldPath)) {
                        $ext = strtolower(pathinfo($oldImagen, PATHINFO_EXTENSION));
                        $base = sanitize_filename($newPlatillo);
                        $newName = $base . '.' . $ext;
                        $newPath = $assetsDir . '/' . $newName;
                        // Si el nuevo path existe y no es el mismo archivo, eliminarlo para reemplazar
                        if (file_exists($newPath) && $newPath !== $oldPath) {
                            @unlink($newPath);
                        }
                        if (@rename($oldPath, $newPath)) {
                            $newImagen = $newName;
                        }
                    }
                }
            }

            // Construir la consulta de actualización dinámicamente según los campos proporcionados
            $fields = [];
            $values = [];
            if ($platillo !== null) { $fields[] = 'Platillo = ?'; $values[] = $newPlatillo; }
            if ($precio !== null) { $fields[] = 'Precio = ?'; $values[] = $precio; }
            if ($descripcion !== null) { $fields[] = 'Descripcion = ?'; $values[] = $descripcion; }
            if ($id_categoria !== null) { $fields[] = 'ID_Categoria = ?'; $values[] = $id_categoria; }
            if ($id_estado !== null) { $fields[] = 'ID_Estado = ?'; $values[] = $id_estado; }
            if ($newImagen !== null) { $fields[] = 'Imagen = ?'; $values[] = $newImagen; }

            if (count($fields) === 0) { echo json_encode(['success' => true, 'message' => 'No hay cambios']); exit; }

            $values[] = $id_menu;
            $sql = 'UPDATE menu SET ' . implode(', ', $fields) . ' WHERE ID_Menu = ?';
            $stmt = $pdo->prepare($sql);
            $success = $stmt->execute($values);
            if ($success) echo json_encode(['success' => true, 'message' => 'Platillo actualizado', 'imagen' => $newImagen]);
            else echo json_encode(['success' => false, 'message' => 'Error actualizando platillo']);
        } catch (PDOException $e) { echo json_encode(['success' => false, 'message' => 'Error actualizando platillo: ' . $e->getMessage()]); }
        exit;
    }

    // ----------------------- CREAR PEDIDO -----------------------
    if ($action === 'create_order') {
        $total = $input_data['total'] ?? 0;
        $ubicacion = $input_data['ubicacion'] ?? null;
        $telefono = $input_data['telefono'] ?? null;
        $items = $input_data['items'] ?? [];
        $user_id = isset($input_data['user_id']) ? $input_data['user_id'] : null;

        // Validaciones básicas
        if (empty($items) || !is_array($items) || trim((string)$ubicacion) === '') {
            echo json_encode(['success' => false, 'message' => 'Items y ubicación son requeridos']);
            exit;
        }

        try {
            error_log('create_order: begin transaction');
            $pdo->beginTransaction();

            // Insertar un único pedido que representa la orden completa

            $firstMenuId = null;
            if (isset($items[0])) {
                $firstMenuId = $items[0]['id'] ?? ($items[0]['ID_Menu'] ?? null);
            }

            // Obtener columnas existentes en la tabla pedidos
            $colsStmt = $pdo->prepare("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'pedidos'");
            $colsStmt->execute([$dbname]);
            $cols = $colsStmt->fetchAll(PDO::FETCH_COLUMN, 0);
            $colsLower = array_map('strtolower', $cols);

            // Determinar nombre de la columna de usuario (si existe)
            $possibleUserCols = ['id_usuarios', 'id_usuario', 'id_Usuario', 'Id_Usuario', 'Id_Usuarios'];
            $userCol = null;
            foreach ($possibleUserCols as $c) {
                if (in_array(strtolower($c), $colsLower)) {
                    // recuperar la forma original con mayúsculas si está en $cols
                    foreach ($cols as $original) {
                        if (strtolower($original) === strtolower($c)) { $userCol = $original; break; }
                    }
                    if ($userCol === null) $userCol = $c;
                    break;
                }
            }

            // Determinar si la columna Platillo existe
            $platilloCol = null;
            foreach ($cols as $c) {
                if (strtolower($c) === 'platillo') { $platilloCol = $c; break; }
            }

            // Construir INSERT dinámico según columnas disponibles
            $fields = [];
            $placeholders = [];
            $values = [];

            if ($platilloCol !== null) {
                $fields[] = $platilloCol;
                $placeholders[] = '?';
                $values[] = $firstMenuId;
            }
            if ($userCol !== null) {
                $fields[] = $userCol;
                $placeholders[] = '?';
                $values[] = $user_id === null ? null : $user_id;
            }
            // Total y Ubicacion (esperadas)
            if (in_array('Total', $cols, true) || in_array('total', $colsLower, true)) {
                // buscar nombre original si existe
                $totalCol = null;
                foreach ($cols as $c) { if (strtolower($c) === 'total') { $totalCol = $c; break; } }
                $fields[] = $totalCol ?? 'Total';
                $placeholders[] = '?';
                $values[] = $total;
            } else {
                // Si no existe Total, seguimos pero con riesgo; añadimos anyway
                $fields[] = 'Total'; $placeholders[] = '?'; $values[] = $total;
            }
            if (in_array('Ubicacion', $cols, true) || in_array('ubicacion', $colsLower, true)) {
                $ubicCol = null; foreach ($cols as $c) { if (strtolower($c) === 'ubicacion') { $ubicCol = $c; break; } }
                $fields[] = $ubicCol ?? 'Ubicacion';
                $placeholders[] = '?';
                $values[] = $ubicacion;
            } else {
                $fields[] = 'Ubicacion'; $placeholders[] = '?'; $values[] = $ubicacion;
            }
            // Telefono en la tabla pedidos si está disponible
            if (in_array('Telefono', $cols, true) || in_array('telefono', $colsLower, true)) {
                $telCol = null; foreach ($cols as $c) { if (strtolower($c) === 'telefono') { $telCol = $c; break; } }
                $fields[] = $telCol ?? 'Telefono';
                $placeholders[] = '?';
                $values[] = $telefono;
            }

            $sql = "INSERT INTO pedidos (" . implode(', ', $fields) . ") VALUES (" . implode(', ', $placeholders) . ")";
            try {
                $stmtPedido = $pdo->prepare($sql);
                $stmtPedido->execute($values);
                $orderId = $pdo->lastInsertId();
                error_log('create_order: inserted pedidos id=' . $orderId . ' sql=' . $sql);
            } catch (PDOException $e) {
                error_log('create_order: insert pedidos failed: ' . $e->getMessage() . ' sql=' . $sql);
                throw $e; // subir el error para que el catch externo haga rollback
            }


            try {
                $maxStmt = $pdo->prepare("SELECT COALESCE(MAX(ID_Platillos_Pedido), 0) AS maxid FROM Platillos_Pedido FOR UPDATE");
                $maxStmt->execute();
                $rowMax = $maxStmt->fetch(PDO::FETCH_ASSOC);
                $nextId = intval($rowMax['maxid']);
            } catch (PDOException $e) {
                // Si falla la lectura del max, fallback a 0 (no ideal, pero evitamos abortar la orden completa)
                error_log('create_order: warning could not lock Platillos_Pedido for id allocation: ' . $e->getMessage());
                $nextId = 0;
            }

            $stmtItem = $pdo->prepare("INSERT INTO Platillos_Pedido (ID_Platillos_Pedido, Nombre_Platillo, Cantidad, Precio, ID_Pedido, ID_Menu) VALUES (?, ?, ?, ?, ?, ?)");
            foreach ($items as $it) {
                $idMenu = $it['id'] ?? ($it['ID_Menu'] ?? null);
                $cantidad = intval($it['quantity'] ?? ($it['cantidad'] ?? 1));
                $precio = floatval($it['price'] ?? 0);
                $nombre = $it['name'] ?? ($it['Nombre_Platillo'] ?? '');

                // Asignar ID único
                $nextId++;

                if ($idMenu === null) {
                    $stmtItem->execute([$nextId, $nombre, $cantidad, $precio, $orderId, null]);
                } else {
                    $stmtItem->execute([$nextId, $nombre, $cantidad, $precio, $orderId, $idMenu]);
                }
                error_log('create_order: inserted Platillos_Pedido item id=' . $nextId . ' name=' . $nombre . ' qty=' . $cantidad);
            }

            // Auto-assign feature disabled: leave assignment manual so repartidores
            // can take pedidos desde su vista. This simplifies behavior: orders
            // created here remain with repartidor=NULL and must be claimed via
            // the `assign_order` endpoint from the repartidor UI.
            $assignedRepartidor = null;
            error_log('create_order: auto-assign disabled (manual assignment only)');

            $pdo->commit();
            error_log('create_order: commit successful for order id=' . $orderId);

            // Determinar columna ID real de la tabla `pedidos` y columna FK en Platillos_Pedido
            try {
                $colsStmt2 = $pdo->prepare("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'pedidos'");
                $colsStmt2->execute([$dbname]);
                $cols2 = $colsStmt2->fetchAll(PDO::FETCH_COLUMN, 0);
                $idCol = null;
                foreach ($cols2 as $c) { $low = strtolower($c); if (in_array($low, ['id_pedido','idpedidos','id','id_pedidos'])) { $idCol = $c; break; } }
                if ($idCol === null && count($cols2) > 0) $idCol = $cols2[0];
            } catch (Exception $e) {
                $idCol = null;
            }

            try {
                $colsItemStmt = $pdo->prepare("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'Platillos_Pedido'");
                $colsItemStmt->execute([$dbname]);
                $itemCols = $colsItemStmt->fetchAll(PDO::FETCH_COLUMN, 0);
                $itemIdCol = null;
                foreach ($itemCols as $c) { if (strtolower($c) === 'id_pedido') { $itemIdCol = $c; break; } }
                if ($itemIdCol === null) {
                    foreach ($itemCols as $c) { if (strpos(strtolower($c), 'pedido') !== false) { $itemIdCol = $c; break; } }
                }
                if ($itemIdCol === null) $itemIdCol = 'ID_Pedido';
            } catch (Exception $e) {
                $itemIdCol = 'ID_Pedido';
            }

            // Asegurar que el pedido quede sin repartidor y con estado Pendiente (si aplica)
            try {
                // Determinar nombre de columna repartidor y estado si existen
                $repartidorCol = null; $estadoCol = null;
                foreach ($cols2 as $c) { $low = strtolower($c); if (in_array($low, ['id_repartidor','idrepartidor','repartidor_id','id_repartidores'])) $repartidorCol = $c; if (in_array($low, ['estado','estado_pedido','status'])) $estadoCol = $c; }

                if ($repartidorCol !== null) {
                    $upd = $pdo->prepare("UPDATE pedidos SET {$repartidorCol} = NULL WHERE {$idCol} = ?");
                    $upd->execute([$orderId]);
                }
                if ($estadoCol !== null) {
                    // determinar tipo de columna estado
                    $colTypeStmt = $pdo->prepare("SELECT DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'pedidos' AND COLUMN_NAME = ? LIMIT 1");
                    $colTypeStmt->execute([$dbname, $estadoCol]);
                    $colType = $colTypeStmt->fetchColumn();
                    $isNumericEstado = in_array(strtolower($colType), ['int','tinyint','smallint','bigint','mediumint']);
                    $val = $isNumericEstado ? 0 : 'Pendiente';
                    $upd2 = $pdo->prepare("UPDATE pedidos SET {$estadoCol} = ? WHERE {$idCol} = ?");
                    $upd2->execute([$val, $orderId]);
                }
            } catch (Exception $e) {
                error_log('create_order: ensure defaults failed: ' . $e->getMessage());
            }

            // Recuperar el pedido insertado y sus items para incluir en la respuesta
            try {
                if ($idCol !== null) {
                    $stmt = $pdo->prepare("SELECT * FROM pedidos WHERE {$idCol} = ? LIMIT 1");
                    $stmt->execute([$orderId]);
                    $pedidoRow = $stmt->fetch(PDO::FETCH_ASSOC);
                } else { $pedidoRow = null; }
            } catch (Exception $e) { $pedidoRow = null; }
            try {
                $stmtItems = $pdo->prepare("SELECT * FROM Platillos_Pedido WHERE {$itemIdCol} = ?");
                $stmtItems->execute([$orderId]);
                $itemsRow = $stmtItems->fetchAll(PDO::FETCH_ASSOC);
            } catch (Exception $e) { $itemsRow = []; }

            $response = ['success' => true, 'message' => 'Pedido creado', 'order_id' => $orderId, 'pedido' => $pedidoRow, 'items' => $itemsRow];
            if ($assignedRepartidor !== null) $response['assigned_repartidor'] = $assignedRepartidor;
            echo json_encode($response);
        } catch (PDOException $e) {
            if ($pdo->inTransaction()) $pdo->rollBack();
            error_log('create_order: error ' . $e->getMessage());
            echo json_encode(['success' => false, 'message' => 'Error creando pedido: ' . $e->getMessage()]);
        }
        exit;
    }

    // ----------------------- OBTENER DETALLE DE PEDIDO -----------------------
    // ----------------------- PEDIDOS PARA REPARTIDOR (TOP-LEVEL HANDLERS) -----------------------
    if ($action === 'get_pending_orders') {
        try {
            // Determinar columna id y posible columna de repartidor/estado
            $colsStmt = $pdo->prepare("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'pedidos'");
            $colsStmt->execute([$dbname]);
            $cols = $colsStmt->fetchAll(PDO::FETCH_COLUMN, 0);
            $colsLower = array_map('strtolower', $cols);

            $idCol = null;
            foreach ($cols as $c) { $low = strtolower($c); if (in_array($low, ['id_pedido','idpedidos','id','id_pedidos'])) { $idCol = $c; break; } }
            if ($idCol === null && count($cols) > 0) $idCol = $cols[0];

            // buscar columna repartidor
            $repartidorCol = null;
            foreach ($cols as $c) { if (in_array(strtolower($c), ['id_repartidor','idrepartidor','repartidor_id','id_repartidores'])) { $repartidorCol = $c; break; } }

            // buscar columna estado
            $estadoCol = null;
                    $excludeFinalWhere = '';

            // buscar columna de visibilidad/ocultar para repartidor (si existe)
            $visibilityCol = null;
            $possibleVisibility = ['ocultar_repartidor','ocultar_a_repartidor','ocultar_repartidores','hide_repartidor','hide_from_repartidor','oculto_repartidor'];
            foreach ($cols as $c) {
                if (in_array(strtolower($c), $possibleVisibility)) { $visibilityCol = $c; break; }
            }
            $visibilityWhere = '';
            if ($visibilityCol !== null) {
                $visibilityWhere = " AND ({$visibilityCol} IS NULL OR {$visibilityCol} = 0)";
            }

            // Permitir al cliente pedir también pedidos asignados (útil para debugging)
            $includeAssigned = false;
            if (isset($input_data['include_assigned'])) {
                $inc = $input_data['include_assigned'];
                $includeAssigned = ($inc === true || $inc === 1 || $inc === '1' || strtolower((string)$inc) === 'true');
            }


                    // buscar columna de visibilidad/ocultar para repartidor (si existe)
                    $visibilityCol = null;
                    $possibleVisibility = ['ocultar_repartidor','ocultar_a_repartidor','ocultar_repartidores','hide_repartidor','hide_from_repartidor','oculto_repartidor'];
                    foreach ($cols as $c) {
                        if (in_array(strtolower($c), $possibleVisibility)) { $visibilityCol = $c; break; }
                    }
                    $visibilityWhere = '';
                    if ($visibilityCol !== null) {
                        $visibilityWhere = " AND ({$visibilityCol} IS NULL OR {$visibilityCol} = 0)";
                    }
            // Construir where: preferimos mostrar pedidos sin repartidor, pero
            // también aceptar filas cuya columna de estado represente 'pendiente'.
            // Detectamos el tipo de la columna estado para aceptar valores numéricos (0/1)
            // o textos ('Pendiente','Listo', etc.). Limite por defecto: 200.
            // Mostrar TODOS los pedidos que aún no tienen repartidor.
            // Excluir solo aquellos pedidos que están claramente finalizados (entregados/cancelados).
            // Detectar si existe columna de estado y su tipo para excluir valores finales apropiadamente.
            $excludeFinalWhere = '';
            $isNumericEstado = false;
            if ($estadoCol !== null) {
                try {
                    $colTypeStmt = $pdo->prepare("SELECT DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'pedidos' AND COLUMN_NAME = ? LIMIT 1");
                    $colTypeStmt->execute([$dbname, $estadoCol]);
                    $colType = $colTypeStmt->fetchColumn();
                    $isNumericEstado = in_array(strtolower($colType), ['int','tinyint','smallint','bigint','mediumint']);
                } catch (Exception $e) {
                    $isNumericEstado = false;
                }
                if ($isNumericEstado) {
                    // 3 suele representar "Entregado"/finalizado en este esquema.
                    $excludeFinalWhere = " AND ({$estadoCol} IS NULL OR {$estadoCol} NOT IN (3))";
                } else {
                    $excludeFinalWhere = " AND ({$estadoCol} IS NULL OR {$estadoCol} NOT IN ('Entregado','entregado','Cancelado','cancelado'))";
                }
            }

            if ($repartidorCol !== null && !$includeAssigned) {
                // comportamiento por defecto: mostrar solo pedidos sin repartidor
                $sql = "SELECT * FROM pedidos WHERE ({$repartidorCol} IS NULL OR {$repartidorCol} = '' OR {$repartidorCol} = 0) " . $excludeFinalWhere . $visibilityWhere . " ORDER BY {$idCol} DESC LIMIT 500";
                $stmt = $pdo->prepare($sql);
                $stmt->execute();
            } else if ($repartidorCol !== null && $includeAssigned) {
                // incluir pedidos asignados tambien: solo aplicar filtros de estado/visibilidad
                $sql = "SELECT * FROM pedidos WHERE 1=1 " . $excludeFinalWhere . $visibilityWhere . " ORDER BY {$idCol} DESC LIMIT 500";
                $stmt = $pdo->prepare($sql);
                $stmt->execute();
            } else if ($estadoCol !== null) {
                // Si no existe columna repartidor, mostrar pedidos cuyo estado no sea final
                if ($isNumericEstado) {
                    $sql = "SELECT * FROM pedidos WHERE ({$estadoCol} IS NULL OR {$estadoCol} NOT IN (3)) " . $visibilityWhere . " ORDER BY {$idCol} DESC LIMIT 500";
                } else {
                    $sql = "SELECT * FROM pedidos WHERE ({$estadoCol} IS NULL OR {$estadoCol} NOT IN ('Entregado','entregado','Cancelado','cancelado')) " . $visibilityWhere . " ORDER BY {$idCol} DESC LIMIT 500";
                }
                $stmt = $pdo->prepare($sql);
                $stmt->execute();
            } else {
                $sql = "SELECT * FROM pedidos ORDER BY {$idCol} DESC LIMIT 500";
                if ($visibilityCol !== null) {
                    // if visibility column exists prefer to exclude hidden ones
                    $sql = "SELECT * FROM pedidos WHERE ({$visibilityCol} IS NULL OR {$visibilityCol} = 0) ORDER BY {$idCol} DESC LIMIT 500";
                }
                $stmt = $pdo->prepare($sql);
                $stmt->execute();
            }
                
            $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
            echo json_encode(['success' => true, 'orders' => $rows]);
        } catch (PDOException $e) {
            echo json_encode(['success' => false, 'message' => 'Error obteniendo pedidos pendientes: ' . $e->getMessage()]);
        }
        exit;
    }

    if ($action === 'get_repartidor_orders') {
        $repartidor_id = $input_data['repartidor_id'] ?? null;
        if ($repartidor_id === null || $repartidor_id === '') { echo json_encode(['success' => false, 'message' => 'repartidor_id requerido']); exit; }
        try {
            // Mapear el ID proporcionado: puede ser ID_Repartidor o ID_Usuario. Queremos obtener el ID_Repartidor real.
            $provided = is_numeric($repartidor_id) ? intval($repartidor_id) : $repartidor_id;
            $targetRepId = null;
            try {
                $chk = $pdo->prepare("SELECT ID_Repartidor, ID_Usuario FROM repartidor WHERE ID_Repartidor = ? LIMIT 1");
                $chk->execute([$provided]);
                $r = $chk->fetch(PDO::FETCH_ASSOC);
                if ($r) $targetRepId = $r['ID_Repartidor'];
                else {
                    $chk2 = $pdo->prepare("SELECT ID_Repartidor, ID_Usuario FROM repartidor WHERE ID_Usuario = ? LIMIT 1");
                    $chk2->execute([$provided]);
                    $r2 = $chk2->fetch(PDO::FETCH_ASSOC);
                    if ($r2) $targetRepId = $r2['ID_Repartidor'];
                }
            } catch (PDOException $e) {
                // Si la tabla repartidor no existe, fallamos con mensaje claro
                error_log('get_repartidor_orders: error consultando repartidor mapping: ' . $e->getMessage());
            }

            $colsStmt = $pdo->prepare("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'pedidos'");
            $colsStmt->execute([$dbname]);
            $cols = $colsStmt->fetchAll(PDO::FETCH_COLUMN, 0);
            $colsLower = array_map('strtolower', $cols);

            $idCol = null;
            foreach ($cols as $c) { $low = strtolower($c); if (in_array($low, ['id_pedido','idpedidos','id','id_pedidos'])) { $idCol = $c; break; } }
            if ($idCol === null && count($cols) > 0) $idCol = $cols[0];

            $repartidorCol = null;
            foreach ($cols as $c) { if (in_array(strtolower($c), ['id_repartidor','idrepartidor','repartidor_id','id_repartidores'])) { $repartidorCol = $c; break; } }

            if ($repartidorCol !== null) {
                if ($targetRepId !== null) {
                    // Respect visibility to repartidores if such column exists
                    $visibilityCol = null;
                    $possibleVisibility = ['ocultar_repartidor','ocultar_a_repartidor','ocultar_repartidores','hide_repartidor','hide_from_repartidor','oculto_repartidor'];
                    foreach ($cols as $c) { if (in_array(strtolower($c), $possibleVisibility)) { $visibilityCol = $c; break; } }
                    $visibilityWhereSql = $visibilityCol ? " AND ({$visibilityCol} IS NULL OR {$visibilityCol} = 0)" : '';
                    $stmt = $pdo->prepare("SELECT * FROM pedidos WHERE {$repartidorCol} = ? " . $visibilityWhereSql . " ORDER BY {$idCol} DESC");
                    $stmt->execute([$targetRepId]);
                } else {
                    // No encontramos mapping; devolver vacío en lugar de intentar con el valor proporcionado
                    $stmt = $pdo->prepare("SELECT * FROM pedidos WHERE 1=0");
                    $stmt->execute();
                }
            } else {
                // Si no hay columna repartidor, devolver vacio (no podemos filtrar)
                $stmt = $pdo->prepare("SELECT * FROM pedidos ORDER BY {$idCol} DESC LIMIT 200");
                $stmt->execute();
            }
            $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
            echo json_encode(['success' => true, 'orders' => $rows]);
        } catch (PDOException $e) {
            echo json_encode(['success' => false, 'message' => 'Error obteniendo pedidos asignados: ' . $e->getMessage()]);
        }
        exit;
    }

    // DEBUG: listar ultimos pedidos sin aplicar filtros (útil para inspección rápida)
    if ($action === 'debug_list_orders') {
        $limit = isset($input_data['limit']) ? intval($input_data['limit']) : 50;
        if ($limit <= 0) $limit = 50;
        try {
            // Determinar la columna id real de la tabla pedidos
            $colsStmt = $pdo->prepare("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'pedidos'");
            $colsStmt->execute([$dbname]);
            $cols = $colsStmt->fetchAll(PDO::FETCH_COLUMN, 0);
            $idCol = null;
            foreach ($cols as $c) {
                $low = strtolower($c);
                if ($low === 'id_pedido' || $low === 'idpedidos' || $low === 'id' || $low === 'id_pedidos') { $idCol = $c; break; }
            }
            if ($idCol === null && count($cols) > 0) $idCol = $cols[0];

            $sql = "SELECT * FROM pedidos ORDER BY {$idCol} DESC LIMIT ?";
            $stmt = $pdo->prepare($sql);
            $stmt->execute([$limit]);
            $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
            echo json_encode(['success' => true, 'count' => count($rows), 'orders' => $rows]);
        } catch (PDOException $e) {
            echo json_encode(['success' => false, 'message' => 'Error debug_list_orders: ' . $e->getMessage()]);
        }
        exit;
    }

    // DEBUG: evaluar por qué una fila concreta sería incluida/excluida por get_pending_orders
    if ($action === 'debug_eval_order') {
        $order_id = $input_data['order_id'] ?? null;
        if (empty($order_id) && $order_id !== 0) { echo json_encode(['success' => false, 'message' => 'order_id requerido']); exit; }
        try {
            // Determinar columnas
            $colsStmt = $pdo->prepare("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'pedidos'");
            $colsStmt->execute([$dbname]);
            $cols = $colsStmt->fetchAll(PDO::FETCH_COLUMN, 0);
            $idCol = null; foreach ($cols as $c) { $low = strtolower($c); if (in_array($low, ['id_pedido','idpedidos','id','id_pedidos'])) { $idCol = $c; break; } }
            if ($idCol === null && count($cols) > 0) $idCol = $cols[0];

            $stmt = $pdo->prepare("SELECT * FROM pedidos WHERE {$idCol} = ? LIMIT 1");
            $stmt->execute([$order_id]);
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            if (!$row) { echo json_encode(['success' => false, 'message' => 'Pedido no encontrado']); exit; }

            // Evaluar condiciones tal como hace get_pending_orders
            $repartidorCol = null; $estadoCol = null; $visibilityCol = null;
            $possibleVisibility = ['ocultar_repartidor','ocultar_a_repartidor','ocultar_repartidores','hide_repartidor','hide_from_repartidor','oculto_repartidor'];
            foreach ($cols as $c) { $low = strtolower($c); if (in_array($low, ['id_repartidor','idrepartidor','repartidor_id','id_repartidores'])) $repartidorCol = $c; if (in_array($low, ['estado','estado_pedido','status'])) $estadoCol = $c; if (in_array($low, $possibleVisibility)) $visibilityCol = $c; }

            $reason = [];

            // visibility
            if ($visibilityCol !== null) {
                $v = $row[$visibilityCol] ?? null;
                if ($v !== null && (int)$v === 1) $reason[] = 'oculto_por_visibility';
            }

            // estado final?
            if ($estadoCol !== null) {
                $val = $row[$estadoCol] ?? null;
                // intentar detectar tipo
                $colTypeStmt = $pdo->prepare("SELECT DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'pedidos' AND COLUMN_NAME = ? LIMIT 1");
                $colTypeStmt->execute([$dbname, $estadoCol]);
                $colType = $colTypeStmt->fetchColumn();
                $isNumericEstado = in_array(strtolower($colType), ['int','tinyint','smallint','bigint','mediumint']);
                if ($isNumericEstado) {
                    if ($val !== null && intval($val) === 3) $reason[] = 'estado_final_numeric_3';
                } else {
                    $low = strtolower((string)$val);
                    if (in_array($low, ['entregado','cancelado'])) $reason[] = 'estado_final_text';
                }
            }

            // repartidor asignado?
            if ($repartidorCol !== null) {
                $r = $row[$repartidorCol] ?? null;
                if ($r !== null && $r !== '' && intval($r) !== 0) $reason[] = 'tiene_repartidor_asignado';
            }

            $included = empty($reason);
            echo json_encode(['success' => true, 'order' => $row, 'included_by_get_pending_orders' => $included, 'exclusion_reasons' => $reason]);
        } catch (PDOException $e) {
            echo json_encode(['success' => false, 'message' => 'Error debug_eval_order: ' . $e->getMessage()]);
        }
        exit;
    }

    // ----------------------- AJUSTAR VISIBILIDAD DE PEDIDO A REPARTIDORES -----------------------
    if ($action === 'set_order_visibility') {
        $order_id = $input_data['order_id'] ?? null;
        if (empty($order_id) && $order_id !== 0) { echo json_encode(['success' => false, 'message' => 'order_id requerido']); exit; }
        if (!isset($input_data['visible'])) { echo json_encode(['success' => false, 'message' => 'visible (0/1 o true/false) requerido']); exit; }
        $visibleParam = $input_data['visible'];
        // normalize boolean-like
        $visible = ($visibleParam === true || $visibleParam === '1' || $visibleParam === 1 || $visibleParam === 'true' || $visibleParam === 't') ? 1 : 0;
        try {
            $colsStmt = $pdo->prepare("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'pedidos'");
            $colsStmt->execute([$dbname]);
            $cols = $colsStmt->fetchAll(PDO::FETCH_COLUMN, 0);
            $visibilityCol = null;
            $possibleVisibility = ['ocultar_repartidor','ocultar_a_repartidor','ocultar_repartidores','hide_repartidor','hide_from_repartidor','oculto_repartidor'];
            foreach ($cols as $c) { if (in_array(strtolower($c), $possibleVisibility)) { $visibilityCol = $c; break; } }
            if ($visibilityCol === null) { echo json_encode(['success' => false, 'message' => 'Tabla pedidos no tiene columna de visibilidad para repartidores']); exit; }

            // determinar columna id
            $idCol = null;
            foreach ($cols as $c) { $low = strtolower($c); if (in_array($low, ['id_pedido','idpedidos','id','id_pedidos'])) { $idCol = $c; break; } }
            if ($idCol === null && count($cols) > 0) $idCol = $cols[0];

            // our visibility convention: 0 or NULL => visible to repartidor; 1 => hidden
            $val = $visible ? 0 : 1; // client asks visible=1 -> store 0 (visible); visible=0 -> store 1 (hidden)
            $upd = $pdo->prepare("UPDATE pedidos SET {$visibilityCol} = ? WHERE {$idCol} = ?");
            $upd->execute([$val, $order_id]);
            if ($upd->rowCount() > 0) echo json_encode(['success' => true, 'message' => 'Visibilidad actualizada']);
            else echo json_encode(['success' => false, 'message' => 'No se actualizó la visibilidad (id inexistente o sin cambios)']);
        } catch (PDOException $e) {
            echo json_encode(['success' => false, 'message' => 'Error set_order_visibility: ' . $e->getMessage()]);
        }
        exit;
    }

    if ($action === 'assign_order') {
        $order_id = $input_data['order_id'] ?? null;
        $repartidor_id = $input_data['repartidor_id'] ?? null;
        if (empty($order_id) || $repartidor_id === null || $repartidor_id === '') { echo json_encode(['success' => false, 'message' => 'order_id y repartidor_id requeridos']); exit; }
        try {
            $colsStmt = $pdo->prepare("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'pedidos'");
            $colsStmt->execute([$dbname]);
            $cols = $colsStmt->fetchAll(PDO::FETCH_COLUMN, 0);
            $repartidorCol = null; $idCol = null; $estadoCol = null;
            foreach ($cols as $c) { $low = strtolower($c); if (in_array($low, ['id_repartidor','idrepartidor','repartidor_id','id_repartidores'])) { $repartidorCol = $c; } if (in_array($low, ['id_pedido','id','id_pedidos','idpedidos'])) { if ($idCol===null) $idCol = $c; } if (in_array($low, ['estado','estado_pedido','status'])) { if ($estadoCol===null) $estadoCol = $c; } }
            if ($idCol === null && count($cols) > 0) $idCol = $cols[0];
            if ($repartidorCol === null) { echo json_encode(['success' => false, 'message' => 'Tabla pedidos no tiene columna para asignar repartidor']); exit; }

            // Normalizar el ID proporcionado
            $providedId = is_numeric($repartidor_id) ? intval($repartidor_id) : $repartidor_id;

            // Intentar mapear el valor proporcionado a un ID_Repartidor válido en la tabla `repartidor`.
            $targetRepId = null;
            try {
                // 1) ¿es el valor directamente un ID_Repartidor?
                $chk = $pdo->prepare("SELECT ID_Repartidor, ID_Usuario FROM repartidor WHERE ID_Repartidor = ? LIMIT 1");
                $chk->execute([$providedId]);
                $r = $chk->fetch(PDO::FETCH_ASSOC);
                if ($r) {
                    $targetRepId = $r['ID_Repartidor'];
                } else {
                    // 2) ¿es el valor un Id_Usuario vinculado en la tabla repartidor?
                    $chk2 = $pdo->prepare("SELECT ID_Repartidor, ID_Usuario FROM repartidor WHERE ID_Usuario = ? LIMIT 1");
                    $chk2->execute([$providedId]);
                    $r2 = $chk2->fetch(PDO::FETCH_ASSOC);
                    if ($r2) {
                        $targetRepId = $r2['ID_Repartidor'];
                    }
                }
            } catch (PDOException $e) {
                // Si la tabla repartidor no existe o hay otro error, lo registramos y fallamos con mensaje claro
                error_log('assign_order: error consultando repartidor mapping: ' . $e->getMessage());
                echo json_encode(['success' => false, 'message' => 'Error consultando repartidor: ' . $e->getMessage()]);
                exit;
            }

            if ($targetRepId === null) {
                echo json_encode(['success' => false, 'message' => 'No se encontró un registro de repartidor para el ID proporcionado (' . $providedId . '). Asegúrate que exista un registro en `repartidor` o que el ID corresponda a la columna `ID_Usuario` mapeada.']);
                exit;
            }

            // Ejecutar la actualización de forma atómica: solo asignar si aún no tiene repartidor
            try {
                // Registrar intento
                error_log('assign_order: attempt order_id=' . $order_id . ' targetRep=' . $targetRepId);
                // Obtener valor actual para información de debug
                $chkPrev = $pdo->prepare("SELECT {$repartidorCol} AS current_rep FROM pedidos WHERE {$idCol} = ? LIMIT 1");
                $chkPrev->execute([$order_id]);
                $prevRow = $chkPrev->fetch(PDO::FETCH_ASSOC);
                $prevRep = $prevRow ? ($prevRow['current_rep'] ?? null) : null;

                $sql = "UPDATE pedidos SET {$repartidorCol} = ?";
                $params = [$targetRepId];
                if ($estadoCol !== null) { $sql .= ", {$estadoCol} = ?"; $params[] = 'Asignado'; }
                // Solo actualizar si no tiene repartidor asignado (NULL, '', 0)
                $sql .= " WHERE {$idCol} = ? AND ({$repartidorCol} IS NULL OR {$repartidorCol} = '' OR {$repartidorCol} = 0)";
                $params[] = $order_id;

                // Support dry-run for testing without modifying the DB
                $dryRun = false;
                if (isset($input_data['dry_run'])) {
                    $d = $input_data['dry_run'];
                    $dryRun = ($d === true || $d === 1 || $d === '1' || strtolower((string)$d) === 'true');
                }

                if ($dryRun) {
                    // Return a simulated updated row without executing UPDATE
                    try {
                        $fetchIdCol = $idCol ?? null;
                        if ($fetchIdCol !== null) {
                            $getStmt = $pdo->prepare("SELECT * FROM pedidos WHERE {$fetchIdCol} = ? LIMIT 1");
                            $getStmt->execute([$order_id]);
                            $row = $getStmt->fetch(PDO::FETCH_ASSOC);
                        } else {
                            $row = null;
                        }
                    } catch (PDOException $e) {
                        $row = null;
                    }
                    if (!$row) {
                        echo json_encode(['success' => false, 'message' => 'Pedido no encontrado (simulación)']);
                    } else {
                        // Simulate assignment
                        $sim = $row;
                        if ($repartidorCol !== null) $sim[$repartidorCol] = $targetRepId;
                        if ($estadoCol !== null) {
                            // detect numeric estado column like elsewhere
                            try {
                                $colTypeStmt = $pdo->prepare("SELECT DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'pedidos' AND COLUMN_NAME = ? LIMIT 1");
                                $colTypeStmt->execute([$dbname, $estadoCol]);
                                $colType = $colTypeStmt->fetchColumn();
                                $isNumericEstado = in_array(strtolower($colType), ['int','tinyint','smallint','bigint','mediumint']);
                            } catch (Exception $e) { $isNumericEstado = false; }
                            $statusMap = ['Asignado' => 0, 'Pendiente' => 0, 'Listo' => 0, 'En Camino' => 1, 'EnCamino' => 1, 'Cerca' => 2, 'Entregado' => 3, 'Finalizado' => 3];
                            if ($isNumericEstado) $sim[$estadoCol] = $statusMap['Asignado']; else $sim[$estadoCol] = 'Asignado';
                        }
                        echo json_encode(['success' => true, 'message' => 'Pedido asignado (simulado)', 'dry_run' => true, 'repartidor_used' => $targetRepId, 'order' => $sim]);
                    }
                } else {
                    $stmt = $pdo->prepare($sql);
                    $stmt->execute($params);
                    if ($stmt->rowCount() > 0) {
                    error_log('assign_order: success order_id=' . $order_id . ' assigned_to=' . $targetRepId);
                    // Recuperar fila actualizada para devolver al cliente
                    try {
                        $fetchIdCol = $idCol ?? null;
                        if ($fetchIdCol !== null) {
                            $getStmt = $pdo->prepare("SELECT * FROM pedidos WHERE {$fetchIdCol} = ? LIMIT 1");
                            $getStmt->execute([$order_id]);
                            $updatedRow = $getStmt->fetch(PDO::FETCH_ASSOC);
                        } else {
                            $updatedRow = null;
                        }
                    } catch (PDOException $e) {
                        $updatedRow = null;
                    }
                    echo json_encode(['success' => true, 'message' => 'Pedido asignado', 'repartidor_used' => $targetRepId, 'order' => $updatedRow]);
                } else {
                    // No se pudo asignar: probablemente ya estaba asignado
                    error_log('assign_order: conflict order_id=' . $order_id . ' prevRep=' . var_export($prevRep, true));
                    $current = $prevRep;
                    if ($current === null || $current === '' || intval($current) === 0) {
                        echo json_encode(['success' => false, 'message' => 'No se actualizó el pedido (id inexistente o sin cambios)']);
                    } else {
                        // También devolver la fila actual para que el cliente pueda ver el repartidor actual
                        $currentRow = null;
                        try {
                            $fetchIdCol = $idCol ?? null;
                            if ($fetchIdCol !== null) {
                                $g = $pdo->prepare("SELECT * FROM pedidos WHERE {$fetchIdCol} = ? LIMIT 1");
                                $g->execute([$order_id]);
                                $currentRow = $g->fetch(PDO::FETCH_ASSOC);
                            }
                        } catch (PDOException $e) { $currentRow = null; }
                        echo json_encode(['success' => false, 'message' => 'Pedido ya asignado', 'current_repartidor' => $current, 'order' => $currentRow]);
                    }
                }
            } catch (PDOException $e) {
                error_log('assign_order: error executing atomic update: ' . $e->getMessage());
                echo json_encode(['success' => false, 'message' => 'Error asignando pedido: ' . $e->getMessage()]);
            }
        } catch (PDOException $e) { echo json_encode(['success' => false, 'message' => 'Error asignando pedido: ' . $e->getMessage()]); }
        exit;
    }

    if ($action === 'update_order_status') {
        $order_id = $input_data['order_id'] ?? null;
        $status = $input_data['status'] ?? null;
        if (empty($order_id) || $status === null) { echo json_encode(['success' => false, 'message' => 'order_id y status requeridos']); exit; }
        try {
            $colsStmt = $pdo->prepare("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'pedidos'");
            $colsStmt->execute([$dbname]);
            $cols = $colsStmt->fetchAll(PDO::FETCH_COLUMN, 0);
            $estadoCol = null; 
            foreach ($cols as $c) {
                $low = strtolower($c);
                if (in_array($low, ['estado','estado_pedido','status'])) { $estadoCol = $c; break; }
            }
            if ($estadoCol === null) { echo json_encode(['success' => false, 'message' => 'Tabla pedidos no tiene columna de estado']); exit; }

            // Normalize provided id: try digits-only numeric value as first attempt
            $originalOrderId = (string)$order_id;
            $digitsOnly = preg_replace('/[^0-9]/', '', $originalOrderId);

            // Candidate id columns to try (prefer common names found in the schema)
            $candidateIdCols = [];
            foreach ($cols as $c) {
                $candidateIdCols[] = $c;
            }
            // Prioritize known id column names
            $preferred = ['ID_Pedido','ID_Pedidos','Id_Pedido','id_pedido','id_pedidos','id','ID','ID_Pedidos'];
            usort($candidateIdCols, function($a, $b) use ($preferred){
                $pa = array_search($a, $preferred);
                $pb = array_search($b, $preferred);
                if ($pa === false) $pa = 999;
                if ($pb === false) $pb = 999;
                return $pa - $pb;
            });

            $found = false;
            $usedIdCol = null;
            $resolvedIdValue = null;

            // Try matching using the original provided value, then digits-only
            $tries = [$originalOrderId];
            if ($digitsOnly !== '' && $digitsOnly !== $originalOrderId) $tries[] = $digitsOnly;

            foreach ($candidateIdCols as $idColCandidate) {
                foreach ($tries as $tryVal) {
                    // Use prepared SELECT to see if a row exists
                    $chk = $pdo->prepare("SELECT 1 FROM pedidos WHERE {$idColCandidate} = ? LIMIT 1");
                    try {
                        $chk->execute([$tryVal]);
                        $r = $chk->fetch(PDO::FETCH_ASSOC);
                        if ($r) {
                            $found = true;
                            $usedIdCol = $idColCandidate;
                            $resolvedIdValue = $tryVal;
                            break 2;
                        }
                    } catch (PDOException $e) {
                        // ignore and try next candidate
                        continue;
                    }
                }
            }

            if (!$found) {
                echo json_encode(['success' => false, 'message' => 'Pedido no encontrado con el id proporcionado']);
                exit;
            }

            // Determine data type of estado column to decide mapping behavior
            $colTypeStmt = $pdo->prepare("SELECT DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'pedidos' AND COLUMN_NAME = ? LIMIT 1");
            $colTypeStmt->execute([$dbname, $estadoCol]);
            $colType = $colTypeStmt->fetchColumn();
            $isNumericEstado = in_array(strtolower($colType), ['int','tinyint','smallint','bigint','mediumint']);

            // Map textual statuses to numeric codes when DB stores numeric codes
            $statusMap = [
                'Asignado' => 0, 'Pendiente' => 0, 'Listo' => 0,
                'En Camino' => 1, 'EnCamino' => 1, 'Cerca' => 2,
                'Entregado' => 3, 'Finalizado' => 3
            ];

            $updateValue = $status;
            if ($isNumericEstado) {
                if (is_numeric($status)) {
                    $updateValue = intval($status);
                } else {
                    $updateValue = array_key_exists($status, $statusMap) ? $statusMap[$status] : (int)preg_replace('/[^0-9]/', '', (string)$status);
                }
            }

            // Support dry-run mode to simulate status update without writing to DB
            $dryRun = false;
            if (isset($input_data['dry_run'])) {
                $d = $input_data['dry_run'];
                $dryRun = ($d === true || $d === 1 || $d === '1' || strtolower((string)$d) === 'true');
            }

            if ($dryRun) {
                // Fetch current row and simulate change
                try {
                    $getStmt = $pdo->prepare("SELECT * FROM pedidos WHERE {$usedIdCol} = ? LIMIT 1");
                    $getStmt->execute([$resolvedIdValue]);
                    $row = $getStmt->fetch(PDO::FETCH_ASSOC);
                } catch (PDOException $e) { $row = null; }
                if (!$row) {
                    echo json_encode(['success' => false, 'message' => 'Pedido no encontrado (simulación)']);
                } else {
                    $sim = $row;
                    $sim[$estadoCol] = $updateValue;
                    echo json_encode(['success' => true, 'message' => 'Estado actualizado (simulado)', 'dry_run' => true, 'order' => $sim]);
                }
            } else {
                $stmt = $pdo->prepare("UPDATE pedidos SET {$estadoCol} = ? WHERE {$usedIdCol} = ?");
                $stmt->execute([$updateValue, $resolvedIdValue]);
                if ($stmt->rowCount() > 0) {
                    // Recuperar fila actualizada y devolverla para actualización inmediata en clientes
                    try {
                        $getStmt = $pdo->prepare("SELECT * FROM pedidos WHERE {$usedIdCol} = ? LIMIT 1");
                        $getStmt->execute([$resolvedIdValue]);
                        $updatedRow = $getStmt->fetch(PDO::FETCH_ASSOC);
                    } catch (PDOException $e) { $updatedRow = null; }
                    echo json_encode(['success' => true, 'message' => 'Estado actualizado', 'order' => $updatedRow]);

                    // After a status change: previously the system enforced a per-repartidor cap
                    // (3) and attempted to auto-assign pending orders to reach that cap. That
                    // behavior is disabled: do not enforce limits or auto-reassign here.
                    try {
                        // no-op: limit enforcement and auto-reassign disabled
                    } catch (PDOException $e) {
                        error_log('update_order_status: repartidor reassign skipped/disabled: ' . $e->getMessage());
                    }

                } else {
                // No rows affected: fetch current status to provide a clearer reason,
                // but be tolerant when comparing textual/numeric representations.
                try {
                    $chk = $pdo->prepare("SELECT {$estadoCol} AS current_status FROM pedidos WHERE {$usedIdCol} = ? LIMIT 1");
                    $chk->execute([$resolvedIdValue]);
                    $row = $chk->fetch(PDO::FETCH_ASSOC);
                    $current = $row ? ($row['current_status'] ?? null) : null;
                    $current_label = null;

                    // Build case-insensitive map for textual status mapping
                    $statusMapLower = [];
                    foreach ($statusMap as $k => $v) { $statusMapLower[strtolower($k)] = $v; }
                    $reverseMap = array_flip($statusMap); // value => label

                    if ($isNumericEstado && $current !== null) {
                        $intCur = intval($current);
                        if (isset($reverseMap[$intCur])) $current_label = $reverseMap[$intCur];
                    } else if (!$isNumericEstado && $current !== null) {
                        $current_label = (string)$current;
                    }

                    // Determine normalized requested value and normalized current value
                    $equal = false;
                    if ($isNumericEstado) {
                        if (!is_numeric($updateValue)) {
                            $lowerStatus = strtolower(trim((string)$status));
                            if (isset($statusMapLower[$lowerStatus])) $requestedValue = $statusMapLower[$lowerStatus];
                            else $requestedValue = (int)preg_replace('/[^0-9]/', '', (string)$status);
                        } else {
                            $requestedValue = intval($updateValue);
                        }
                        $currentNorm = ($current !== null) ? intval($current) : null;
                        $equal = ($currentNorm !== null && $currentNorm === $requestedValue);
                    } else {
                        $currentNorm = ($current !== null) ? strtolower(trim((string)$current)) : null;
                        $requestedNorm = strtolower(trim((string)$status));
                        $equal = ($currentNorm !== null && $currentNorm === $requestedNorm);
                        $requestedValue = $requestedNorm;
                    }

                    if ($equal) {
                        // devolver la fila actual para sincronización en el cliente
                        try {
                            $getStmt = $pdo->prepare("SELECT * FROM pedidos WHERE {$usedIdCol} = ? LIMIT 1");
                            $getStmt->execute([$resolvedIdValue]);
                            $updatedRow = $getStmt->fetch(PDO::FETCH_ASSOC);
                        } catch (PDOException $e) { $updatedRow = null; }
                        echo json_encode(['success' => true, 'message' => 'Estado ya establecido', 'current_status' => $current, 'current_status_label' => $current_label, 'order' => $updatedRow]);
                    } else {
                        // Return clearer debug info to help clients understand mismatch and include current row
                        try {
                            $getStmt = $pdo->prepare("SELECT * FROM pedidos WHERE {$usedIdCol} = ? LIMIT 1");
                            $getStmt->execute([$resolvedIdValue]);
                            $updatedRow = $getStmt->fetch(PDO::FETCH_ASSOC);
                        } catch (PDOException $e) { $updatedRow = null; }
                        echo json_encode(['success' => false, 'message' => 'No se actualizó (id existente pero sin cambios)', 'current_status' => $current, 'current_status_label' => $current_label, 'requested_raw' => $status, 'requested_mapped' => $requestedValue, 'order' => $updatedRow]);
                    }
                } catch (PDOException $e) {
                    echo json_encode(['success' => false, 'message' => 'No se actualizó (sin cambios)']);
                }
            }
        } catch (PDOException $e) { echo json_encode(['success' => false, 'message' => 'Error actualizando estado: ' . $e->getMessage()]); }
        exit;
    }
    if ($action === 'get_order_detail') {
        $orderId = $input_data['order_id'] ?? $input_data['id'] ?? null;
        if (empty($orderId)) {
            echo json_encode(['success' => false, 'message' => 'order_id requerido']);
            exit;
        }

            // ----------------------- PEDIDOS PARA REPARTIDOR -----------------------
            if ($action === 'get_pending_orders') {
                try {
                    // Determinar columna id y posible columna de repartidor/estado
                    $colsStmt = $pdo->prepare("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'pedidos'");
                    $colsStmt->execute([$dbname]);
                    $cols = $colsStmt->fetchAll(PDO::FETCH_COLUMN, 0);
                    $colsLower = array_map('strtolower', $cols);

                    $idCol = null;
                    foreach ($cols as $c) { $low = strtolower($c); if (in_array($low, ['id_pedido','idpedidos','id','id_pedidos'])) { $idCol = $c; break; } }
                    if ($idCol === null && count($cols) > 0) $idCol = $cols[0];

                    // buscar columna repartidor
                    $repartidorCol = null;
                    foreach ($cols as $c) { if (in_array(strtolower($c), ['id_repartidor','idrepartidor','repartidor_id','id_repartidores'])) { $repartidorCol = $c; break; } }

                    // buscar columna estado
                    $estadoCol = null;
                    foreach ($cols as $c) { if (in_array(strtolower($c), ['estado','estado_pedido','status'])) { $estadoCol = $c; break; } }

                    // Mostrar TODOS los pedidos que aún no tienen repartidor.
                    // Excluir solo aquellos pedidos que están claramente finalizados (entregados/cancelados).
                    $excludeFinalWhere = '';
                    $isNumericEstado = false;
                    if ($estadoCol !== null) {
                        try {
                            $colTypeStmt = $pdo->prepare("SELECT DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'pedidos' AND COLUMN_NAME = ? LIMIT 1");
                            $colTypeStmt->execute([$dbname, $estadoCol]);
                            $colType = $colTypeStmt->fetchColumn();
                            $isNumericEstado = in_array(strtolower($colType), ['int','tinyint','smallint','bigint','mediumint']);
                        } catch (Exception $e) {
                            $isNumericEstado = false;
                        }
                        if ($isNumericEstado) {
                            $excludeFinalWhere = " AND ({$estadoCol} IS NULL OR {$estadoCol} NOT IN (3))";
                        } else {
                            $excludeFinalWhere = " AND ({$estadoCol} IS NULL OR {$estadoCol} NOT IN ('Entregado','entregado','Cancelado','cancelado'))";
                        }
                    }

                    if ($repartidorCol !== null) {
                        $sql = "SELECT * FROM pedidos WHERE ({$repartidorCol} IS NULL OR {$repartidorCol} = '' OR {$repartidorCol} = 0) " . $excludeFinalWhere . $visibilityWhere . " ORDER BY {$idCol} DESC LIMIT 500";
                        $stmt = $pdo->prepare($sql);
                        $stmt->execute();
                    } else if ($estadoCol !== null) {
                        if ($isNumericEstado) {
                            $sql = "SELECT * FROM pedidos WHERE ({$estadoCol} IS NULL OR {$estadoCol} NOT IN (3)) " . $visibilityWhere . " ORDER BY {$idCol} DESC LIMIT 500";
                        } else {
                            $sql = "SELECT * FROM pedidos WHERE ({$estadoCol} IS NULL OR {$estadoCol} NOT IN ('Entregado','entregado','Cancelado','cancelado')) " . $visibilityWhere . " ORDER BY {$idCol} DESC LIMIT 500";
                        }
                        $stmt = $pdo->prepare($sql);
                        $stmt->execute();
                    } else {
                        $sql = "SELECT * FROM pedidos ORDER BY {$idCol} DESC LIMIT 500";
                        if ($visibilityCol !== null) {
                            $sql = "SELECT * FROM pedidos WHERE ({$visibilityCol} IS NULL OR {$visibilityCol} = 0) ORDER BY {$idCol} DESC LIMIT 500";
                        }
                        $stmt = $pdo->prepare($sql);
                        $stmt->execute();
                    }

                    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
                    echo json_encode(['success' => true, 'orders' => $rows]);
                } catch (PDOException $e) {
                    echo json_encode(['success' => false, 'message' => 'Error obteniendo pedidos pendientes: ' . $e->getMessage()]);
                }
                exit;
            }

            if ($action === 'get_repartidor_orders') {
                $repartidor_id = $input_data['repartidor_id'] ?? null;
                if (empty($repartidor_id)) { echo json_encode(['success' => false, 'message' => 'repartidor_id requerido']); exit; }
                try {
                    $colsStmt = $pdo->prepare("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'pedidos'");
                    $colsStmt->execute([$dbname]);
                    $cols = $colsStmt->fetchAll(PDO::FETCH_COLUMN, 0);
                    $colsLower = array_map('strtolower', $cols);

                    $idCol = null;
                    foreach ($cols as $c) { $low = strtolower($c); if (in_array($low, ['id_pedido','idpedidos','id','id_pedidos'])) { $idCol = $c; break; } }
                    if ($idCol === null && count($cols) > 0) $idCol = $cols[0];

                    $repartidorCol = null;
                    foreach ($cols as $c) { if (in_array(strtolower($c), ['id_repartidor','idrepartidor','repartidor_id','id_repartidores'])) { $repartidorCol = $c; break; } }

                    if ($repartidorCol !== null) {
                        // Respect visibility to repartidores if such column exists
                        $visibilityCol = null;
                        $possibleVisibility = ['ocultar_repartidor','ocultar_a_repartidor','ocultar_repartidores','hide_repartidor','hide_from_repartidor','oculto_repartidor'];
                        foreach ($cols as $c) { if (in_array(strtolower($c), $possibleVisibility)) { $visibilityCol = $c; break; } }
                        $visibilityWhereSql = $visibilityCol ? " AND ({$visibilityCol} IS NULL OR {$visibilityCol} = 0)" : '';
                        $stmt = $pdo->prepare("SELECT * FROM pedidos WHERE {$repartidorCol} = ? " . $visibilityWhereSql . " ORDER BY {$idCol} DESC");
                        $stmt->execute([$repartidor_id]);
                    } else {
                        // Si no hay columna repartidor, devolver vacio (no podemos filtrar)
                        $stmt = $pdo->prepare("SELECT * FROM pedidos ORDER BY {$idCol} DESC LIMIT 200");
                        $stmt->execute();
                    }
                    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
                    echo json_encode(['success' => true, 'orders' => $rows]);
                } catch (PDOException $e) {
                    echo json_encode(['success' => false, 'message' => 'Error obteniendo pedidos asignados: ' . $e->getMessage()]);
                }
                exit;
            }

            if ($action === 'assign_order') {
                $order_id = $input_data['order_id'] ?? null;
                $repartidor_id = $input_data['repartidor_id'] ?? null;
                if (empty($order_id) || $repartidor_id === null || $repartidor_id === '') { echo json_encode(['success' => false, 'message' => 'order_id y repartidor_id requeridos']); exit; }
                try {
                    $colsStmt = $pdo->prepare("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'pedidos'");
                    $colsStmt->execute([$dbname]);
                    $cols = $colsStmt->fetchAll(PDO::FETCH_COLUMN, 0);
                    $repartidorCol = null; $idCol = null; $estadoCol = null;
                    foreach ($cols as $c) { $low = strtolower($c); if (in_array($low, ['id_repartidor','idrepartidor','repartidor_id','id_repartidores'])) { $repartidorCol = $c; } if (in_array($low, ['id_pedido','id','id_pedidos','idpedidos'])) { if ($idCol===null) $idCol = $c; } if (in_array($low, ['estado','estado_pedido','status'])) { if ($estadoCol===null) $estadoCol = $c; } }
                    if ($idCol === null && count($cols) > 0) $idCol = $cols[0];
                    if ($repartidorCol === null) { echo json_encode(['success' => false, 'message' => 'Tabla pedidos no tiene columna para asignar repartidor']); exit; }

                    // Normalizar el ID proporcionado
                    $providedId = is_numeric($repartidor_id) ? intval($repartidor_id) : $repartidor_id;

                    // Intentar mapear el valor proporcionado a un ID_Repartidor válido en la tabla `repartidor`.
                    $targetRepId = null;
                    try {
                        // 1) ¿es el valor directamente un ID_Repartidor?
                        $chk = $pdo->prepare("SELECT ID_Repartidor, ID_Usuario FROM repartidor WHERE ID_Repartidor = ? LIMIT 1");
                        $chk->execute([$providedId]);
                        $r = $chk->fetch(PDO::FETCH_ASSOC);
                        if ($r) {
                            $targetRepId = $r['ID_Repartidor'];
                        } else {
                            // 2) ¿es el valor un Id_Usuario vinculado en la tabla repartidor?
                            $chk2 = $pdo->prepare("SELECT ID_Repartidor, ID_Usuario FROM repartidor WHERE ID_Usuario = ? LIMIT 1");
                            $chk2->execute([$providedId]);
                            $r2 = $chk2->fetch(PDO::FETCH_ASSOC);
                            if ($r2) {
                                $targetRepId = $r2['ID_Repartidor'];
                            }
                        }
                    } catch (PDOException $e) {
                        // Si la tabla repartidor no existe o hay otro error, lo registramos y fallamos con mensaje claro
                        error_log('assign_order: error consultando repartidor mapping: ' . $e->getMessage());
                        echo json_encode(['success' => false, 'message' => 'Error consultando repartidor: ' . $e->getMessage()]);
                        exit;
                    }

                    if ($targetRepId === null) {
                        echo json_encode(['success' => false, 'message' => 'No se encontró un registro de repartidor para el ID proporcionado (' . $providedId . '). Asegúrate que exista un registro en `repartidor` o que el ID corresponda a la columna `ID_Usuario` mapeada.']);
                        exit;
                    }

                    // Ejecutar la actualización de forma atómica: solo asignar si aún no tiene repartidor
                    try {
                        // Registrar intento
                        error_log('assign_order: attempt order_id=' . $order_id . ' targetRep=' . $targetRepId);
                        // Obtener valor actual para información de debug
                        $chkPrev = $pdo->prepare("SELECT {$repartidorCol} AS current_rep FROM pedidos WHERE {$idCol} = ? LIMIT 1");
                        $chkPrev->execute([$order_id]);
                        $prevRow = $chkPrev->fetch(PDO::FETCH_ASSOC);
                        $prevRep = $prevRow ? ($prevRow['current_rep'] ?? null) : null;

                        $sql = "UPDATE pedidos SET {$repartidorCol} = ?";
                        $params = [$targetRepId];
                        if ($estadoCol !== null) { $sql .= ", {$estadoCol} = ?"; $params[] = 'Asignado'; }
                        // Solo actualizar si no tiene repartidor asignado (NULL, '', 0)
                        $sql .= " WHERE {$idCol} = ? AND ({$repartidorCol} IS NULL OR {$repartidorCol} = '' OR {$repartidorCol} = 0)";
                        $params[] = $order_id;
                        $stmt = $pdo->prepare($sql);
                        $stmt->execute($params);
                        if ($stmt->rowCount() > 0) {
                            error_log('assign_order: success order_id=' . $order_id . ' assigned_to=' . $targetRepId);
                            echo json_encode(['success' => true, 'message' => 'Pedido asignado', 'repartidor_used' => $targetRepId]);
                        } else {
                            // No se pudo asignar: probablemente ya estaba asignado
                            error_log('assign_order: conflict order_id=' . $order_id . ' prevRep=' . var_export($prevRep, true));
                            $current = $prevRep;
                            if ($current === null || $current === '' || intval($current) === 0) {
                                echo json_encode(['success' => false, 'message' => 'No se actualizó el pedido (id inexistente o sin cambios)']);
                            } else {
                                echo json_encode(['success' => false, 'message' => 'Pedido ya asignado', 'current_repartidor' => $current]);
                            }
                        }
                    } catch (PDOException $e) {
                        error_log('assign_order: error executing atomic update: ' . $e->getMessage());
                        echo json_encode(['success' => false, 'message' => 'Error asignando pedido: ' . $e->getMessage()]);
                    }
                } catch (PDOException $e) { echo json_encode(['success' => false, 'message' => 'Error asignando pedido: ' . $e->getMessage()]); }
                exit;
            }

            if ($action === 'update_order_status') {
                $order_id = $input_data['order_id'] ?? null;
                $status = $input_data['status'] ?? null;
                if (empty($order_id) || $status === null) { echo json_encode(['success' => false, 'message' => 'order_id y status requeridos']); exit; }
                try {
                    $colsStmt = $pdo->prepare("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'pedidos'");
                    $colsStmt->execute([$dbname]);
                    $cols = $colsStmt->fetchAll(PDO::FETCH_COLUMN, 0);
                    $estadoCol = null;
                    foreach ($cols as $c) {
                        $low = strtolower($c);
                        if (in_array($low, ['estado','estado_pedido','status'])) { $estadoCol = $c; break; }
                    }
                    if ($estadoCol === null) { echo json_encode(['success' => false, 'message' => 'Tabla pedidos no tiene columna de estado']); exit; }

                    $originalOrderId = (string)$order_id;
                    $digitsOnly = preg_replace('/[^0-9]/', '', $originalOrderId);

                    $candidateIdCols = [];
                    foreach ($cols as $c) { $candidateIdCols[] = $c; }
                    $preferred = ['ID_Pedido','ID_Pedidos','Id_Pedido','id_pedido','id_pedidos','id','ID','ID_Pedidos'];
                    usort($candidateIdCols, function($a, $b) use ($preferred){
                        $pa = array_search($a, $preferred);
                        $pb = array_search($b, $preferred);
                        if ($pa === false) $pa = 999;
                        if ($pb === false) $pb = 999;
                        return $pa - $pb;
                    });

                    $found = false; $usedIdCol = null; $resolvedIdValue = null;
                    $tries = [$originalOrderId];
                    if ($digitsOnly !== '' && $digitsOnly !== $originalOrderId) $tries[] = $digitsOnly;
                    foreach ($candidateIdCols as $idColCandidate) {
                        foreach ($tries as $tryVal) {
                            $chk = $pdo->prepare("SELECT 1 FROM pedidos WHERE {$idColCandidate} = ? LIMIT 1");
                            try { $chk->execute([$tryVal]); $r = $chk->fetch(PDO::FETCH_ASSOC); if ($r) { $found = true; $usedIdCol = $idColCandidate; $resolvedIdValue = $tryVal; break 2; } } catch (PDOException $e) { continue; }
                        }
                    }
                    if (!$found) { echo json_encode(['success' => false, 'message' => 'Pedido no encontrado con el id proporcionado']); exit; }

                    // Determine data type of estado column to decide mapping behavior
                    $colTypeStmt = $pdo->prepare("SELECT DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'pedidos' AND COLUMN_NAME = ? LIMIT 1");
                    $colTypeStmt->execute([$dbname, $estadoCol]);
                    $colType = $colTypeStmt->fetchColumn();
                    $isNumericEstado = in_array(strtolower($colType), ['int','tinyint','smallint','bigint','mediumint']);

                    $statusMap = [
                        'Asignado' => 0, 'Pendiente' => 0, 'Listo' => 0,
                        'En Camino' => 1, 'EnCamino' => 1, 'Cerca' => 2,
                        'Entregado' => 3, 'Finalizado' => 3
                    ];

                    $updateValue = $status;
                    if ($isNumericEstado) {
                        if (is_numeric($status)) {
                            $updateValue = intval($status);
                        } else {
                            $updateValue = array_key_exists($status, $statusMap) ? $statusMap[$status] : (int)preg_replace('/[^0-9]/', '', (string)$status);
                        }
                    }

                    $stmt = $pdo->prepare("UPDATE pedidos SET {$estadoCol} = ? WHERE {$usedIdCol} = ?");
                    $stmt->execute([$updateValue, $resolvedIdValue]);
                    if ($stmt->rowCount() > 0) {
                        echo json_encode(['success' => true, 'message' => 'Estado actualizado']);
                    } else {
                        try {
                            $chk = $pdo->prepare("SELECT {$estadoCol} AS current_status FROM pedidos WHERE {$usedIdCol} = ? LIMIT 1");
                            $chk->execute([$resolvedIdValue]);
                            $row = $chk->fetch(PDO::FETCH_ASSOC);
                            $current = $row ? ($row['current_status'] ?? null) : null;
                            $current_label = null;
                            if ($isNumericEstado && $current !== null) {
                                $rev = array_search(intval($current), $statusMap, true);
                                if ($rev !== false) $current_label = $rev;
                            }
                            echo json_encode(['success' => false, 'message' => 'No se actualizó (id existente pero mismo estado o sin cambios)', 'current_status' => $current, 'current_status_label' => $current_label]);
                        } catch (PDOException $e) {
                            echo json_encode(['success' => false, 'message' => 'No se actualizó (sin cambios)']);
                        }
                    }
                } catch (PDOException $e) { echo json_encode(['success' => false, 'message' => 'Error actualizando estado: ' . $e->getMessage()]); }
                exit;
            }

        try {
            // Obtener columnas reales de la tabla pedidos para localizar la columna ID
            $colsStmt = $pdo->prepare("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'pedidos'");
            $colsStmt->execute([$dbname]);
            $cols = $colsStmt->fetchAll(PDO::FETCH_COLUMN, 0);

            $idCol = null;
            // Buscar una columna que sea claramente el id del pedido
            foreach ($cols as $c) {
                $low = strtolower($c);
                if ($low === 'id_pedido' || $low === 'idpedidos' || $low === 'id' || $low === 'id_pedidos') { $idCol = $c; break; }
            }
            if ($idCol === null) {
                foreach ($cols as $c) {
                    $low = strtolower($c);
                    if (strpos($low, 'pedido') !== false && strpos($low, 'id') !== false) { $idCol = $c; break; }
                }
            }
            if ($idCol === null && count($cols) > 0) $idCol = $cols[0]; // fallback

            // Consultar el pedido
            $stmt = $pdo->prepare("SELECT * FROM pedidos WHERE {$idCol} = ? LIMIT 1");
            $stmt->execute([$orderId]);
            $pedido = $stmt->fetch(PDO::FETCH_ASSOC);
            if (!$pedido) {
                echo json_encode(['success' => false, 'message' => 'Pedido no encontrado']);
                exit;
            }

            // Obtener items desde Platillos_Pedido; localizar la columna FK hacia pedidos
            $colsItemStmt = $pdo->prepare("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'Platillos_Pedido'");
            $colsItemStmt->execute([$dbname]);
            $itemCols = $colsItemStmt->fetchAll(PDO::FETCH_COLUMN, 0);
            $itemIdCol = null;
            foreach ($itemCols as $c) {
                if (strtolower($c) === 'id_pedido') { $itemIdCol = $c; break; }
            }
            if ($itemIdCol === null) {
                foreach ($itemCols as $c) {
                    if (strpos(strtolower($c), 'pedido') !== false) { $itemIdCol = $c; break; }
                }
            }
            if ($itemIdCol === null) $itemIdCol = 'ID_Pedido';

            $stmtItems = $pdo->prepare("SELECT * FROM Platillos_Pedido WHERE {$itemIdCol} = ?");
            $stmtItems->execute([$orderId]);
            $items = $stmtItems->fetchAll(PDO::FETCH_ASSOC);

            echo json_encode(['success' => true, 'pedido' => $pedido, 'items' => $items]);
        } catch (PDOException $e) {
            echo json_encode(['success' => false, 'message' => 'Error obteniendo detalle: ' . $e->getMessage()]);
        }
        exit;
    }

    // ----------------------- ADMIN: LISTAR TODOS LOS PEDIDOS (HISTORIAL) -----------------------
    if ($action === 'get_all_orders') {
        try {
            $limit = isset($input_data['limit']) ? intval($input_data['limit']) : 1000;
            $offset = isset($input_data['offset']) ? intval($input_data['offset']) : 0;
            if ($limit <= 0) $limit = 1000;

            // Determinar columna id
            $colsStmt = $pdo->prepare("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'pedidos'");
            $colsStmt->execute([$dbname]);
            $cols = $colsStmt->fetchAll(PDO::FETCH_COLUMN, 0);
            $idCol = null;
            foreach ($cols as $c) { $low = strtolower($c); if (in_array($low, ['id_pedido','idpedidos','id','id_pedidos'])) { $idCol = $c; break; } }
            if ($idCol === null && count($cols) > 0) $idCol = $cols[0];

            $sql = "SELECT * FROM pedidos ORDER BY {$idCol} DESC LIMIT ? OFFSET ?";
            $stmt = $pdo->prepare($sql);
            $stmt->execute([$limit, $offset]);
            $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
            echo json_encode(['success' => true, 'count' => count($rows), 'orders' => $rows]);
        } catch (PDOException $e) {
            echo json_encode(['success' => false, 'message' => 'Error get_all_orders: ' . $e->getMessage()]);
        }
        exit;
    }

    // ----------------------- ADMIN: ELIMINAR PEDIDOS (SINGLE O MULTI) -----------------------
    if ($action === 'delete_orders') {
        // Accept either single order_id or array order_ids
        $ids = [];
        if (isset($input_data['order_id'])) {
            $ids[] = $input_data['order_id'];
        }
        if (isset($input_data['order_ids']) && is_array($input_data['order_ids'])) {
            foreach ($input_data['order_ids'] as $v) $ids[] = $v;
        }
        if (empty($ids)) { echo json_encode(['success' => false, 'message' => 'order_id o order_ids requerido']); exit; }

        // Seguridad: requerir admin_key para operaciones destructivas
        $providedKey = $input_data['admin_key'] ?? $input_data['adminKey'] ?? '';
        if (empty($providedKey) || $providedKey !== $ADMIN_DELETE_KEY) {
            echo json_encode(['success' => false, 'message' => 'admin_key requerido o inválido']);
            exit;
        }

        try {
            $pdo->beginTransaction();

            // Determinar columna id en pedidos
            $colsStmt = $pdo->prepare("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'pedidos'");
            $colsStmt->execute([$dbname]);
            $cols = $colsStmt->fetchAll(PDO::FETCH_COLUMN, 0);
            $idCol = null; foreach ($cols as $c) { $low = strtolower($c); if (in_array($low, ['id_pedido','idpedidos','id','id_pedidos'])) { $idCol = $c; break; } }
            if ($idCol === null && count($cols) > 0) $idCol = $cols[0];

            // Determinar FK columna en Platillos_Pedido
            $colsItemStmt = $pdo->prepare("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'Platillos_Pedido'");
            $colsItemStmt->execute([$dbname]);
            $itemCols = $colsItemStmt->fetchAll(PDO::FETCH_COLUMN, 0);
            $itemIdCol = null;
            foreach ($itemCols as $c) { if (strtolower($c) === 'id_pedido') { $itemIdCol = $c; break; } }
            if ($itemIdCol === null) {
                foreach ($itemCols as $c) { if (strpos(strtolower($c), 'pedido') !== false) { $itemIdCol = $c; break; } }
            }
            if ($itemIdCol === null) $itemIdCol = 'ID_Pedido';

            $deleted = 0;
            foreach ($ids as $rawId) {
                $orderId = $rawId;
                // Delete items first if table exists
                try {
                    $delItems = $pdo->prepare("DELETE FROM Platillos_Pedido WHERE {$itemIdCol} = ?");
                    $delItems->execute([$orderId]);
                } catch (PDOException $e) {
                    // ignore if table missing, but continue
                }
                // Delete order
                $del = $pdo->prepare("DELETE FROM pedidos WHERE {$idCol} = ?");
                $del->execute([$orderId]);
                $deleted += $del->rowCount();
            }

            $pdo->commit();
            echo json_encode(['success' => true, 'message' => 'Pedidos eliminados', 'deleted' => $deleted]);
        } catch (PDOException $e) {
            if ($pdo->inTransaction()) $pdo->rollBack();
            echo json_encode(['success' => false, 'message' => 'Error delete_orders: ' . $e->getMessage()]);
        }
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
    if ($action === 'login') {
        $email = $input_data['email'] ?? '';
        $password = $input_data['password'] ?? '';
        // Log ligero para depuración si intentan hacer login por accidente
        error_log('Login branch invoked. action=' . var_export($action, true) . ' input_preview=' . substr(json_encode(is_array($input_data) ? $input_data : []), 0, 300));
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

    // Si ninguna acción coincide -> devolver información útil para debug
    // No dejar datos sensibles por mucho tiempo en producción; esto es para depuración local.
    error_log('Acción no reconocida. action=' . var_export($action, true) . ' input_preview=' . substr(json_encode($input_data), 0, 400));
    $input_preview = substr(json_encode($input_data), 0, 400);
    echo json_encode(['success' => false, 'message' => 'Acción no reconocida', 'action_received' => $action, 'input_preview' => $input_preview]);

} catch (PDOException $e) {
    echo json_encode(['success' => false, 'message' => 'Error de conexión: ' . $e->getMessage()]);
}

?>