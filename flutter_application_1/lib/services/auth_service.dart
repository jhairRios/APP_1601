import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // URL de tu API PHP - MISMA URL que login_screen.dart
  static const String _baseUrl = 'http://localhost/Aplicacion_1/APP1601/APP_1601/flutter_application_1/php/api.php';
  
  // Instancia de Google Sign In
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Configuración básica sin scopes específicos para evitar errores
  );

  // Método para login con Google
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // MODO REAL: Google Sign-In verdadero
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // Usuario canceló el login
        return {'success': false, 'message': 'Login cancelado por el usuario'};
      }

      // Obtener información real del usuario
      final String email = googleUser.email;
      final String name = googleUser.displayName ?? 'Usuario Google';

      print('Usuario Google real: $email, $name');

      // Enviar datos al backend PHP
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'action': 'google_login',
          'email': email,
          'name': name,
        },
      );

      print('Respuesta del servidor: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = json.decode(response.body);
        return result;
      } else {
        return {'success': false, 'message': 'Error del servidor: ${response.statusCode}'};
      }
    } catch (e) {
      print('Error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Método para cerrar sesión
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  // Método para obtener el usuario actual
  static GoogleSignInAccount? getCurrentUser() {
    return _googleSignIn.currentUser;
  }

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
        return {'success': false, 'message': 'Error del servidor: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}