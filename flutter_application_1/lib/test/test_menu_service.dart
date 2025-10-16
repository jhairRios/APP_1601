import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_config.dart';

Future<void> testMenuService() async {
  try {
    final response = await http.get(Uri.parse('$API_BASE_URL?action=get_menu'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        print('Datos del menú cargados correctamente:');
        print(data['menu']);
      } else {
        print('Error en la respuesta del servidor: ${data['message']}');
      }
    } else {
      print('Error HTTP: ${response.statusCode}');
    }
  } catch (e) {
    print('Error al probar el servicio del menú: $e');
  }
}

void main() {
  testMenuService();
}
