// Configuración centralizada de la URL base del API
// Cambia esta constante a la URL pública donde esté desplegado tu PHP en AWS
// Configuración centralizada de la URL base del API
// Modo híbrido (desarrollo local + BD en AWS): apunta al PHP que correrás en Laragon/Apache.
// Usa esta URL mientras desarrollas localmente. Cuando despliegues PHP en un servidor público,
// reemplaza este valor por la URL pública (https://mi-servidor/.../php/api.php).
const String API_BASE_URL = 'https://4dc1d0fd4725.ngrok-free.app/Aplicacion_1/APP1601/APP_1601/flutter_application_1';
// Ejemplos de uso:
// Uri.parse('$API_BASE_URL?action=get_roles')
// Uri.parse(API_BASE_URL)
