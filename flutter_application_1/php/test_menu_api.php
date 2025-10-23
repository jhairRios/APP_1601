<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

echo "=== TEST MENU API ===\n\n";

// Test 1: Verificar método
echo "REQUEST_METHOD: " . $_SERVER['REQUEST_METHOD'] . "\n";
echo "CONTENT_TYPE: " . ($_SERVER['CONTENT_TYPE'] ?? 'no definido') . "\n\n";

// Test 2: Ver datos GET
echo "GET Parameters:\n";
print_r($_GET);
echo "\n";

// Test 3: Ver datos POST
echo "POST Parameters:\n";
print_r($_POST);
echo "\n";

// Test 4: Ver raw input
echo "Raw Input:\n";
$raw = file_get_contents('php://input');
echo $raw . "\n\n";

// Test 5: Decodificar JSON
if (!empty($raw)) {
    echo "JSON Decoded:\n";
    $decoded = json_decode($raw, true);
    print_r($decoded);
    echo "\n";
}

// Test 6: Action
$action = $_GET['action'] ?? null;
echo "Action detectado: " . ($action ?? 'ninguno') . "\n";
?>
