<?php
// Debug listing of repartidores (HTML view)
// Place this file under the same folder as api.php and open it via your web server.

// Database config (must match api.php)
$host = 'mi-mysql-db.c6j6ewui4d46.us-east-1.rds.amazonaws.com';
$port = '3306';
$dbname = 'App1601';
$username = 'admin';
$password = 'JhairRios_2005';

try {
    $dsn = "mysql:host={$host};port={$port};dbname={$dbname};charset=utf8mb4";
    $pdo = new PDO($dsn, $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

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

    // Build query
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

    // If user asked for JSON, return it
    if (isset($_GET['format']) && $_GET['format'] === 'json') {
        header('Content-Type: application/json');
        echo json_encode(['success' => true, 'repartidores' => $rows]);
        exit;
    }

    // Otherwise render simple HTML table
    ?>
    <!doctype html>
    <html lang="es">
    <head>
      <meta charset="utf-8">
      <title>Lista de Repartidores</title>
      <style>
        body { font-family: Arial, sans-serif; padding: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; }
        th { background: #f4f4f4; }
      </style>
    </head>
    <body>
      <h1>Repartidores</h1>
      <p>Si quieres obtener JSON usa <code>?format=json</code> en la URL.</p>
      <table>
        <thead>
          <tr>
            <th>ID_Repartidor</th>
            <th>Nombre</th>
            <th>Estado_Repartidor</th>
            <th>assigned_count</th>
            <th>Otros (debug)</th>
          </tr>
        </thead>
        <tbody>
    <?php
    foreach ($rows as $r) {
        $id = htmlspecialchars($r['ID_Repartidor'] ?? $r['id'] ?? '');
        $nombre = htmlspecialchars($r['Nombre'] ?? $r['nombre'] ?? $r['name'] ?? '');
        $estado = htmlspecialchars($r['Estado_Repartidor'] ?? $r['estado'] ?? '');
        $count = htmlspecialchars($r['assigned_count'] ?? 0);
        $others = htmlspecialchars(json_encode($r));
        echo "<tr><td>{$id}</td><td>{$nombre}</td><td>{$estado}</td><td>{$count}</td><td style=\"font-size:10px;\">{$others}</td></tr>";
    }
    ?>
        </tbody>
      </table>
    </body>
    </html>
    <?php

} catch (PDOException $e) {
    header('Content-Type: text/plain');
    echo 'Error DB: ' . $e->getMessage();
}
