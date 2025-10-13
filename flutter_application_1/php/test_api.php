<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

try {
    echo json_encode(['ok' => true, 'message' => 'test_api.php reachable', 'time' => date('c')]);
} catch (Exception $e) {
    echo json_encode(['ok' => false, 'error' => $e->getMessage()]);
}
