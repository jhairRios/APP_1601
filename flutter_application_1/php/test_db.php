<?php
// Configuración de la base de datos
$host = 'localhost';
$dbname = 'app1601';
$username = 'root';
$password = '';

try {
    // Conectar a la base de datos
    $pdo = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "✅ Conexión exitosa a la base de datos<br><br>";
    
    // Consultar todos los usuarios (incluyendo inactivos)
    $stmt = $pdo->prepare("
        SELECT u.Id_Usuario, u.Nombre, u.Correo, u.Telefono, u.Fecha_Registro, 
               u.Id_Rol, u.activo, r.Descripcion
        FROM usuarios u 
        LEFT JOIN rol r ON u.Id_Rol = r.Id_Rol 
        ORDER BY u.Fecha_Registro DESC
    ");
    $stmt->execute();
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "📊 Total de usuarios encontrados: " . count($users) . "<br><br>";
    
    if (count($users) > 0) {
        echo "<table border='1' cellpadding='10'>";
        echo "<tr><th>ID</th><th>Nombre</th><th>Correo</th><th>Teléfono</th><th>Rol</th><th>Activo</th></tr>";
        
        foreach ($users as $user) {
            $activo = $user['activo'] == 1 ? '✅ SÍ' : '❌ NO';
            echo "<tr>";
            echo "<td>" . $user['Id_Usuario'] . "</td>";
            echo "<td>" . $user['Nombre'] . "</td>";
            echo "<td>" . $user['Correo'] . "</td>";
            echo "<td>" . ($user['Telefono'] ?? 'N/A') . "</td>";
            echo "<td>" . ($user['Descripcion'] ?? 'Sin rol') . "</td>";
            echo "<td>" . $activo . "</td>";
            echo "</tr>";
        }
        echo "</table>";
    } else {
        echo "❌ No hay usuarios en la tabla 'usuarios'";
    }
    
    // Consultar roles
    $stmt = $pdo->prepare("SELECT Id_Rol, Descripcion FROM rol ORDER BY Descripcion");
    $stmt->execute();
    $roles = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "<br><br>📝 Roles disponibles: " . count($roles) . "<br><br>";
    
    if (count($roles) > 0) {
        echo "<table border='1' cellpadding='10'>";
        echo "<tr><th>ID Rol</th><th>Descripción</th></tr>";
        
        foreach ($roles as $rol) {
            echo "<tr>";
            echo "<td>" . $rol['Id_Rol'] . "</td>";
            echo "<td>" . $rol['Descripcion'] . "</td>";
            echo "</tr>";
        }
        echo "</table>";
    }
    
} catch (PDOException $e) {
    echo "❌ Error de conexión: " . $e->getMessage();
}
?>