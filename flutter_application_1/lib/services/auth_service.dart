import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // URL de tu API PHP - MISMA URL que login_screen.dart
  static const String _baseUrl =
      'http://localhost/APP_1601/flutter_application_1/php/api.php';

  // ✅ NUEVO: Método para registrar usuario
  static Future<Map<String, dynamic>> registerUser({
    required String nombre,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'action': 'register',
          'nombre': nombre,
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = json.decode(response.body);
        return result;
      } else {
        return {
          'success': false,
          'message': 'Error del servidor: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
