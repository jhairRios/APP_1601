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

    // Si ninguna acción coincide
    echo json_encode(['success' => false, 'message' => 'Acción no reconocida']);

} catch (PDOException $e) {
    echo json_encode(['success' => false, 'message' => 'Error de conexión: ' . $e->getMessage()]);
}

?>