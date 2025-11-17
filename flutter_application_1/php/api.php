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
            $json_data = json_decode(file_get_contents('php://input'), true);
            if ($json_data) $input_data = $json_data;
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
            // Use SHOW COLUMNS which is often allowed even when INFORMATION_SCHEMA access is restricted
            $colsStmt = $pdo->prepare("SHOW COLUMNS FROM pedidos");
            $colsStmt->execute();
            $colsRaw = $colsStmt->fetchAll(PDO::FETCH_ASSOC);
            $cols = array_map(function($r){ return $r['Field']; }, $colsRaw);
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

            // Determinar columna repartidor si existe, para forzar NULL en el INSERT
            $repartidorCol = null;
            foreach ($cols as $c) {
                if (in_array(strtolower($c), ['id_repartidor','idrepartidor','repartidor_id','id_repartidores'])) { $repartidorCol = $c; break; }
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
            // Insertar explicitamente NULL en la columna de repartidor (si existe)
            // para evitar que un DEFAULT de la base de datos o trigger le ponga
            // un valor distinto. Esto asegura que el pedido se cree sin repartidor.
            if ($repartidorCol !== null) {
                $fields[] = $repartidorCol;
                $placeholders[] = '?';
                $values[] = null;
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

            // Auto-assignment of repartidores has been disabled.
            // Previously the system attempted to auto-assign available repartidores
            // and enforce a per-repartidor cap (e.g. 3 active orders). That behavior
            // is intentionally removed to keep assignment manual.
            $assignedRepartidor = null;

            // Defensive safety: Ensure the repartidor column (if present) is NULL
            // for the newly created order to avoid any accidental assignment from
            // other processes or DB defaults/triggers. This is executed inside
            // the current transaction so it will be atomic with the order creation.
            try {
                $repartidorCol = null; $idCol = null;
                foreach ($cols as $c) {
                    $low = strtolower($c);
                    if (in_array($low, ['id_repartidor','idrepartidor','repartidor_id','id_repartidores'])) { $repartidorCol = $c; }
                    if (in_array($low, ['id_pedido','idpedidos','id','id_pedidos']) && $idCol === null) { $idCol = $c; }
                }
                if ($idCol === null && count($cols) > 0) $idCol = $cols[0];
                if ($repartidorCol !== null) {
                    $clearSql = "UPDATE pedidos SET {$repartidorCol} = NULL WHERE {$idCol} = ?";
                    $clearStmt = $pdo->prepare($clearSql);
                    $clearStmt->execute([$orderId]);
                    error_log('create_order: cleared repartidorCol ' . $repartidorCol . ' for order ' . $orderId);
                }
            } catch (PDOException $e) {
                // No fatal error: continue and commit, but log for inspection
                error_log('create_order: failed to clear repartidor col: ' . $e->getMessage());
            }

            $pdo->commit();
            error_log('create_order: commit successful for order id=' . $orderId);
            // Fetch the inserted row to return full order details to clients for immediate sync
            try {
                $sel = $pdo->prepare("SELECT * FROM pedidos WHERE {$idCol} = ? LIMIT 1");
                $sel->execute([$orderId]);
                $insertedRow = $sel->fetch(PDO::FETCH_ASSOC);
            } catch (PDOException $e) { $insertedRow = null; }
            $response = ['success' => true, 'message' => 'Pedido creado', 'order_id' => $orderId, 'order' => $insertedRow];
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

    // ----------------------- OBTENER TODO EL HISTORIAL DE PEDIDOS (ADMIN / EMPLEADO) -----------------------
    if ($action === 'get_all_orders') {
        $limit = isset($input_data['limit']) ? intval($input_data['limit']) : 1000;
        try {
            $colsStmt = $pdo->prepare("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'pedidos'");
            $colsStmt->execute([$dbname]);
            $cols = $colsStmt->fetchAll(PDO::FETCH_COLUMN, 0);
            $idCol = null;
            foreach ($cols as $c) { $low = strtolower($c); if (in_array($low, ['id_pedido','idpedidos','id','id_pedidos'])) { $idCol = $c; break; } }
            if ($idCol === null && count($cols) > 0) $idCol = $cols[0];

            $sql = "SELECT * FROM pedidos ORDER BY {$idCol} DESC LIMIT ?";
            $stmt = $pdo->prepare($sql);
            $stmt->execute([$limit]);
            $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
            echo json_encode(['success' => true, 'orders' => $rows]);
        } catch (PDOException $e) {
            echo json_encode(['success' => false, 'message' => 'Error obteniendo historial de pedidos: ' . $e->getMessage()]);
        }
        exit;
    }

    // ----------------------- DEBUG: RECENT ASSIGNMENTS -----------------------
    if ($action === 'debug_recent_assignments') {
        $limit = isset($input_data['limit']) ? intval($input_data['limit']) : 50;
        try {
            $colsStmt = $pdo->prepare("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'pedidos'");
            $colsStmt->execute([$dbname]);
            $cols = $colsStmt->fetchAll(PDO::FETCH_COLUMN, 0);
            $idCol = null; $repartidorCol = null;
            foreach ($cols as $c) {
                $low = strtolower($c);
                if (in_array($low, ['id_pedido','idpedidos','id','id_pedidos']) && $idCol === null) $idCol = $c;
                if (in_array($low, ['id_repartidor','idrepartidor','repartidor_id','id_repartidores']) && $repartidorCol === null) $repartidorCol = $c;
            }
            if ($idCol === null && count($cols) > 0) $idCol = $cols[0];
            if ($repartidorCol === null) { echo json_encode(['success' => false, 'message' => 'Tabla pedidos no tiene columna repartidor']); exit; }

            // Quote column identifiers with backticks to avoid reserved-word issues
            $rCol = str_replace('`', '', $repartidorCol);
            $iCol = str_replace('`', '', $idCol);
            $limitInt = intval($limit);
            $sql = "SELECT * FROM pedidos WHERE (`{$rCol}` IS NOT NULL AND `{$rCol}` != '' AND `{$rCol}` != 0) ORDER BY `{$iCol}` DESC LIMIT {$limitInt}";
            $stmt = $pdo->prepare($sql);
            $stmt->execute();
            $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
            echo json_encode(['success' => true, 'count' => count($rows), 'orders' => $rows]);
        } catch (PDOException $e) {
            // Log full error and SQL for debugging
            if (isset($sql)) error_log('debug_recent_assignments SQL: ' . $sql);
            error_log('debug_recent_assignments error: ' . $e->getMessage());
            echo json_encode([
                'success' => false,
                'message' => 'Error debug recent assignments: ' . $e->getMessage(),
                'sql' => isset($sql) ? $sql : null,
            ]);
        }
        exit;
    }

    // ----------------------- DESASIGNAR PEDIDOS (ADMIN / DEPURACIÓN) -----------------------
    if ($action === 'unassign_orders') {
        // Parámetros:
        //  - order_id (opcional): desasigna un pedido específico
        //  - all (opcional, boolean 1/true): desasigna todos los pedidos que actualmente tienen repartidor asignado y no estén entregados
        //  - repartidor_id (opcional): desasigna todos los pedidos asignados a ese repartidor
        $order_id = $input_data['order_id'] ?? null;
        $all = isset($input_data['all']) && ($input_data['all'] === '1' || $input_data['all'] === 1 || $input_data['all'] === true);
        $repartidor_id = $input_data['repartidor_id'] ?? null;

        try {
            $colsStmt = $pdo->prepare("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'pedidos'");
            $colsStmt->execute([$dbname]);
            $cols = $colsStmt->fetchAll(PDO::FETCH_COLUMN, 0);
            $repartidorCol = null; $idCol = null; $estadoCol = null;
            foreach ($cols as $c) {
                $low = strtolower($c);
                if (in_array($low, ['id_repartidor','idrepartidor','repartidor_id','id_repartidores'])) { $repartidorCol = $c; }
                if (in_array($low, ['id_pedido','id','id_pedidos','idpedidos'])) { if ($idCol===null) $idCol = $c; }
                if (in_array($low, ['estado','estado_pedido','status'])) { if ($estadoCol===null) $estadoCol = $c; }
            }
            if ($idCol === null && count($cols) > 0) $idCol = $cols[0];
            if ($repartidorCol === null) { echo json_encode(['success' => false, 'message' => 'Tabla pedidos no tiene columna repartidor']); exit; }

            // Construir condiciones
            if ($order_id !== null && $order_id !== '') {
                $sql = "UPDATE pedidos SET {$repartidorCol} = NULL WHERE {$idCol} = ?";
                $stmt = $pdo->prepare($sql);
                $stmt->execute([$order_id]);
                echo json_encode(['success' => true, 'message' => 'Pedido desasignado', 'order_id' => $order_id, 'rows_affected' => $stmt->rowCount()]);
                exit;
            }

            if ($repartidor_id !== null && $repartidor_id !== '') {
                $sql = "UPDATE pedidos SET {$repartidorCol} = NULL WHERE {$repartidorCol} = ?";
                // evitar desasignar entregados: si existe columna estado, filtrar
                if ($estadoCol !== null) {
                    $sql .= " AND ({$estadoCol} IS NULL OR ({$estadoCol} NOT IN ('Entregado','entregado','Finalizado','finalizado','Cancelado','cancelado')))";
                }
                $stmt = $pdo->prepare($sql);
                $stmt->execute([$repartidor_id]);
                echo json_encode(['success' => true, 'message' => 'Pedidos desasignados por repartidor', 'repartidor_id' => $repartidor_id, 'rows_affected' => $stmt->rowCount()]);
                exit;
            }

            if ($all) {
                $sql = "UPDATE pedidos SET {$repartidorCol} = NULL WHERE ({$repartidorCol} IS NOT NULL AND {$repartidorCol} != '' AND {$repartidorCol} != 0)";
                if ($estadoCol !== null) {
                    $sql .= " AND ({$estadoCol} IS NULL OR ({$estadoCol} NOT IN ('Entregado','entregado','Finalizado','finalizado','Cancelado','cancelado')))";
                }
                $stmt = $pdo->prepare($sql);
                $stmt->execute();
                echo json_encode(['success' => true, 'message' => 'Todos los pedidos asignados pendientes han sido desasignados', 'rows_affected' => $stmt->rowCount()]);
                exit;
            }

            echo json_encode(['success' => false, 'message' => 'Parámetros inválidos: proporciona order_id, repartidor_id o all=1']);
        } catch (PDOException $e) {
            echo json_encode(['success' => false, 'message' => 'Error desasignando pedidos: ' . $e->getMessage()]);
        }
        exit;
    }

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
            foreach ($cols as $c) { if (in_array(strtolower($c), ['estado','estado_pedido','status'])) { $estadoCol = $c; break; } }

            // Construir where: preferimos filtrar por estado (Pendiente/Listo) para mostrar
            // los pedidos en la vista de empleados incluso si ya están asignados a un repartidor.
            if ($estadoCol !== null) {
                $sql = "SELECT * FROM pedidos WHERE {$estadoCol} IN ('Pendiente','pendiente', 'Listo', 'listo') ORDER BY {$idCol} DESC LIMIT 200";
                $stmt = $pdo->prepare($sql);
                $stmt->execute();
            } else if ($repartidorCol !== null) {
                // Fallback: si no existe columna de estado, mostrar pedidos sin repartidor
                $sql = "SELECT * FROM pedidos WHERE ({$repartidorCol} IS NULL OR {$repartidorCol} = '' OR {$repartidorCol} = 0) ORDER BY {$idCol} DESC LIMIT 200";
                $stmt = $pdo->prepare($sql);
                $stmt->execute();
            } else {
                $stmt = $pdo->prepare("SELECT * FROM pedidos ORDER BY {$idCol} DESC LIMIT 200");
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
                    $stmt = $pdo->prepare("SELECT * FROM pedidos WHERE {$repartidorCol} = ? ORDER BY {$idCol} DESC");
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

            // Ejecutar la actualización *solo si* el pedido aún no tiene repartidor asignado.
            // Esto implementa un comportamiento de "primer repartidor que toma el pedido lo obtiene".
            // IMPORTANTE: no cambiamos el estado aquí. El repartidor debe actualizar el estado
            // explícitamente con `update_order_status` (por ejemplo: Iniciar, En Camino, Entregado).
            $sql = "UPDATE pedidos SET {$repartidorCol} = ?";
            $params = [$targetRepId];
            // Añadir condición para asegurar que solo se actualice si no hay repartidor asignado todavía
            $sql .= " WHERE {$idCol} = ? AND ({$repartidorCol} IS NULL OR {$repartidorCol} = '' OR {$repartidorCol} = 0)";
            $params[] = $order_id;
            $stmt = $pdo->prepare($sql);
            $stmt->execute($params);
            if ($stmt->rowCount() > 0) {
                // Asignación exitosa: devolver el pedido actualizado
                try {
                    $sel = $pdo->prepare("SELECT * FROM pedidos WHERE {$idCol} = ? LIMIT 1");
                    $sel->execute([$order_id]);
                    $row = $sel->fetch(PDO::FETCH_ASSOC);
                } catch (PDOException $e) { $row = null; }
                echo json_encode(['success' => true, 'message' => 'Pedido asignado', 'repartidor_used' => $targetRepId, 'order' => $row]);
            } else {
                // No se asignó: probablemente ya tenía un repartidor. Recuperar valor actual para mayor claridad.
                try {
                    $sel = $pdo->prepare("SELECT {$repartidorCol} AS current_repartidor FROM pedidos WHERE {$idCol} = ? LIMIT 1");
                    $sel->execute([$order_id]);
                    $curr = $sel->fetch(PDO::FETCH_ASSOC);
                    $currentRep = $curr ? ($curr['current_repartidor'] ?? null) : null;
                } catch (PDOException $e) { $currentRep = null; }
                echo json_encode(['success' => false, 'message' => 'No se pudo asignar: pedido ya asignado o id inexistente', 'current_repartidor' => $currentRep]);
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
                    // Map common textual labels to numeric codes used in the DB.
                    // Adjust these values to match your DB conventions if different.
                    $statusMap = [
                        'Confirmado' => 0,
                        'Pendiente' => 0,
                        'Asignado' => 0,
                        'Preparando' => 1,
                        'En Preparación' => 1,
                        'En Camino' => 2,
                        'EnCamino' => 2,
                        'Cerca' => 2,
                        'Listo' => 2,
                        'Entregado' => 3,
                        'Finalizado' => 3,
                        'Cancelado' => 4,
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
                // Fetch the updated row and return it so clients (empleado/repartidor)
                // can immediately sync UI without extra requests.
                try {
                    $sel = $pdo->prepare("SELECT * FROM pedidos WHERE {$usedIdCol} = ? LIMIT 1");
                    $sel->execute([$resolvedIdValue]);
                    $updatedRow = $sel->fetch(PDO::FETCH_ASSOC);
                } catch (PDOException $e) { $updatedRow = null; }
                echo json_encode(['success' => true, 'message' => 'Estado actualizado', 'order' => $updatedRow]);

                // Automatic rebalancing/assignment of repartidores has been disabled.
                // We do not modify other orders or repartidor availability here.

            } else {
                // No rows affected: fetch current status to provide a clearer reason
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

                    // Construir where: preferimos filtrar por estado (Pendiente/Listo) para mostrar
                    // los pedidos en la vista de empleados incluso si ya están asignados a un repartidor.
                    if ($estadoCol !== null) {
                        // Detectar tipo de la columna estado: si es numérica, usar códigos; si es textual, usar etiquetas
                        $colTypeStmt = $pdo->prepare("SELECT DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'pedidos' AND COLUMN_NAME = ? LIMIT 1");
                        $colTypeStmt->execute([$dbname, $estadoCol]);
                        $colType = $colTypeStmt->fetchColumn();
                        $isNumericEstado = in_array(strtolower($colType), ['int','tinyint','smallint','bigint','mediumint','decimal']);

                        if ($isNumericEstado) {
                            // consideramos 0/1/2 como pendientes/in-prep/listo según mapping
                            $sql = "SELECT * FROM pedidos WHERE `{$estadoCol}` IN (0,1,2) ORDER BY `{$idCol}` DESC LIMIT 200";
                        } else {
                            // textual statuses
                            $sql = "SELECT * FROM pedidos WHERE `{$estadoCol}` IN ('Pendiente','pendiente','Confirmado','confirmado','Listo','listo') ORDER BY `{$idCol}` DESC LIMIT 200";
                        }
                        $stmt = $pdo->prepare($sql);
                        $stmt->execute();
                    } else if ($repartidorCol !== null) {
                        // Fallback: si no existe columna de estado, mostrar pedidos sin repartidor
                        $sql = "SELECT * FROM pedidos WHERE (`{$repartidorCol}` IS NULL OR `{$repartidorCol}` = '' OR `{$repartidorCol}` = 0) ORDER BY `{$idCol}` DESC LIMIT 200";
                        $stmt = $pdo->prepare($sql);
                        $stmt->execute();
                    } else {
                        $stmt = $pdo->prepare("SELECT * FROM pedidos ORDER BY `{$idCol}` DESC LIMIT 200");
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
                        $stmt = $pdo->prepare("SELECT * FROM pedidos WHERE {$repartidorCol} = ? ORDER BY {$idCol} DESC");
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

                    // Ejecutar la actualización *solo si* el pedido aún no tiene repartidor asignado.
                    // No cambiar el estado aquí: las transiciones de estado deben hacerse
                    // explícitamente mediante `update_order_status` para mantener consistencia.
                    $sql = "UPDATE pedidos SET {$repartidorCol} = ?";
                    $params = [$targetRepId];
                    $sql .= " WHERE {$idCol} = ? AND ({$repartidorCol} IS NULL OR {$repartidorCol} = '' OR {$repartidorCol} = 0)";
                    $params[] = $order_id;
                    $stmt = $pdo->prepare($sql);
                    $stmt->execute($params);
                    if ($stmt->rowCount() > 0) {
                        try {
                            $sel = $pdo->prepare("SELECT * FROM pedidos WHERE {$idCol} = ? LIMIT 1");
                            $sel->execute([$order_id]);
                            $row = $sel->fetch(PDO::FETCH_ASSOC);
                        } catch (PDOException $e) { $row = null; }
                        echo json_encode(['success' => true, 'message' => 'Pedido asignado', 'repartidor_used' => $targetRepId, 'order' => $row]);
                    } else {
                        try {
                            $sel = $pdo->prepare("SELECT {$repartidorCol} AS current_repartidor FROM pedidos WHERE {$idCol} = ? LIMIT 1");
                            $sel->execute([$order_id]);
                            $curr = $sel->fetch(PDO::FETCH_ASSOC);
                            $currentRep = $curr ? ($curr['current_repartidor'] ?? null) : null;
                        } catch (PDOException $e) { $currentRep = null; }
                        echo json_encode(['success' => false, 'message' => 'No se pudo asignar: pedido ya asignado o id inexistente', 'current_repartidor' => $currentRep]);
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
                        try {
                            $sel = $pdo->prepare("SELECT * FROM pedidos WHERE {$usedIdCol} = ? LIMIT 1");
                            $sel->execute([$resolvedIdValue]);
                            $updatedRow = $sel->fetch(PDO::FETCH_ASSOC);
                        } catch (PDOException $e) { $updatedRow = null; }
                        echo json_encode(['success' => true, 'message' => 'Estado actualizado', 'order' => $updatedRow]);
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

    // ----------------------- GET ORDERS VIEW (UNIFICADO PARA VISTAS) -----------------------
    // action=get_orders_view
    // params:
    //   view: 'empleado'|'repartidor'|'admin'|'cliente'
    //   repartidor_id: (opcional) id del repartidor para view=repartidor
    //   user_id: (opcional) id del usuario/cliente para view=cliente
    //   limit, offset: paginación
    if ($action === 'get_orders_view') {
        $view = $input_data['view'] ?? 'empleado';
        $limit = isset($input_data['limit']) ? intval($input_data['limit']) : 200;
        $offset = isset($input_data['offset']) ? intval($input_data['offset']) : 0;
        $repartidor_id = $input_data['repartidor_id'] ?? null;
        $user_id = $input_data['user_id'] ?? null;
        try {
            // Detect columns
            $colsStmt = $pdo->prepare("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'pedidos'");
            $colsStmt->execute([$dbname]);
            $cols = $colsStmt->fetchAll(PDO::FETCH_COLUMN, 0);
            $colsLower = array_map('strtolower', $cols);

            $idCol = null; $repartidorCol = null; $estadoCol = null; $userCol = null;
            foreach ($cols as $c) {
                $low = strtolower($c);
                if (in_array($low, ['id_pedido','idpedidos','id','id_pedidos']) && $idCol === null) $idCol = $c;
                if (in_array($low, ['id_repartidor','idrepartidor','repartidor_id','id_repartidores']) && $repartidorCol === null) $repartidorCol = $c;
                if (in_array($low, ['estado','estado_pedido','status']) && $estadoCol === null) $estadoCol = $c;
                if (in_array($low, ['id_usuarios','id_usuario','idusuario','id_usuario']) && $userCol === null) $userCol = $c;
            }
            if ($idCol === null && count($cols) > 0) $idCol = $cols[0];

            // Build base query and where clauses per view
            $where = [];
            $params = [];

            if ($view === 'empleado') {
                if ($repartidorCol !== null) {
                    $where[] = "({$repartidorCol} IS NULL OR {$repartidorCol} = '' OR {$repartidorCol} = 0)";
                } elseif ($estadoCol !== null) {
                    $where[] = "{$estadoCol} IN ('Pendiente','pendiente','Listo','listo')";
                }
            } elseif ($view === 'repartidor') {
                if ($repartidor_id === null || $repartidor_id === '') {
                    echo json_encode(['success' => false, 'message' => 'repartidor_id requerido para view=repartidor']); exit;
                }
                if ($repartidorCol !== null) {
                    $where[] = "{$repartidorCol} = ?"; $params[] = $repartidor_id;
                } else {
                    // fallback: no repartidor column -> empty result
                    echo json_encode(['success' => true, 'orders' => [], 'count' => 0]); exit;
                }
            } elseif ($view === 'cliente') {
                if ($user_id === null || $user_id === '') {
                    echo json_encode(['success' => false, 'message' => 'user_id requerido para view=cliente']); exit;
                }
                if ($userCol !== null) {
                    $where[] = "{$userCol} = ?"; $params[] = $user_id;
                } else {
                    // try common names in schema
                    foreach ($cols as $c) {
                        if (stripos($c, 'usuario') !== false) { $userCol = $c; break; }
                    }
                    if ($userCol !== null) { $where[] = "{$userCol} = ?"; $params[] = $user_id; }
                    else { echo json_encode(['success' => true, 'orders' => [], 'count' => 0]); exit; }
                }
            } elseif ($view === 'admin') {
                // admin sees all orders; no extra filters
            } else {
                echo json_encode(['success' => false, 'message' => 'view desconocida']); exit;
            }

            $sql = "SELECT * FROM pedidos";
            if (count($where) > 0) $sql .= " WHERE " . implode(' AND ', $where);
            $sql .= " ORDER BY {$idCol} DESC LIMIT ? OFFSET ?";
            $params[] = $limit; $params[] = $offset;

            $stmt = $pdo->prepare($sql);
            $stmt->execute($params);
            $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

            // return normalized response
            echo json_encode(['success' => true, 'view' => $view, 'count' => count($rows), 'orders' => $rows]);
        } catch (PDOException $e) {
            echo json_encode(['success' => false, 'message' => 'Error obteniendo orders view: ' . $e->getMessage()]);
        }
        exit;
    }

    echo json_encode(['success' => false, 'message' => 'Acción no reconocida']);

} catch (PDOException $e) {
    echo json_encode(['success' => false, 'message' => 'Error de conexión: ' . $e->getMessage()]);
}

?>