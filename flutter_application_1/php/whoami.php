<?php
header('Content-Type: application/json; charset=utf-8');
$resp = [];
$resp['whoami_path'] = __FILE__;
$resp['whoami_mtime'] = file_exists(__FILE__) ? filemtime(__FILE__) : null;
$apiPath = __DIR__ . DIRECTORY_SEPARATOR . 'api.php';
if (file_exists($apiPath)) {
    $resp['api_path'] = realpath($apiPath);
    $resp['api_mtime'] = filemtime($apiPath);
    // md5 ayuda a comparar rápidamente si la copia es la misma entre entornos
    $resp['api_md5'] = md5_file($apiPath);
} else {
    $resp['api_path'] = null;
    $resp['api_mtime'] = null;
    $resp['api_md5'] = null;
}
$resp['server_time'] = date(DATE_ATOM);
$resp['php_sapi'] = php_sapi_name();
echo json_encode($resp, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
?>