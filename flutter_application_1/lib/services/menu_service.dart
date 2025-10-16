import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';

class MenuService {
  static const String _baseUrl = API_BASE_URL;

  static Future<List<dynamic>> getMenuItems() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl?action=get_menu'));
      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse is Map<String, dynamic> &&
            decodedResponse['menu'] is List) {
          return decodedResponse['menu'];
        } else {
          throw Exception('Formato de respuesta inesperado');
        }
      } else {
        throw Exception(
          'Error al obtener los datos del menú: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error en getMenuItems: $e');
      return [];
    }
  }

  static Future<bool> addMenuItem(Map<String, dynamic> menuItem) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?menu'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(menuItem),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        print('Error al agregar el platillo: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error en addMenuItem: $e');
      return false;
    }
  }
}
