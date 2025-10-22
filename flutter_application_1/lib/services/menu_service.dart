import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'api_config.dart';
import 'package:http_parser/http_parser.dart';

class MenuService {
  static const String _baseUrl = API_BASE_URL;

  static Future<List<dynamic>> getCategorias() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?action=get_categorias'),
      );
      print('Respuesta cruda getCategorias: \\n${response.body}');
      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse is Map<String, dynamic> &&
            decodedResponse['categorias'] is List) {
          return decodedResponse['categorias'];
        } else {
          throw Exception('Formato de respuesta inesperado');
        }
      } else {
        throw Exception(
          'Error al obtener las categorías: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error en getCategorias: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getMenuItems() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl?action=get_menu'));
      print('Respuesta cruda getMenuItems: ${response.body}');
      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse is Map<String, dynamic> &&
            decodedResponse['menu'] is List) {
          return List<Map<String, dynamic>>.from(
            decodedResponse['menu'].where((e) => e is Map<String, dynamic>),
          );
        }
      }
      return [];
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

  /// Añade un platillo con posibilidad de enviar imagen como bytes (multipart).
  /// Si [imageBytes] es null, se usa el método JSON simple.
  static Future<bool> addMenuItemWithImage(
    Map<String, dynamic> menuItem, {
    Uint8List? imageBytes,
    String imageFilename = 'imagen.jpg',
  }) async {
    try {
      if (imageBytes == null) {
        return await addMenuItem(menuItem);
      }
      final uri = Uri.parse('$_baseUrl?action=add_menu_item');
      final request = http.MultipartRequest('POST', uri);
      // Agregar campos
      menuItem.forEach((key, value) {
        if (value != null) request.fields[key] = value.toString();
      });
      // Agregar archivo
      request.files.add(
        http.MultipartFile.fromBytes(
          'imagen_file',
          imageBytes,
          filename: imageFilename,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
      final streamed = await request.send();
      final respStr = await streamed.stream.bytesToString();
      if (streamed.statusCode == 200) {
        return true;
      }
      print(
        'Error multipart addMenuItemWithImage: ${streamed.statusCode} -> $respStr',
      );
      return false;
    } catch (e) {
      print('Error en addMenuItemWithImage: $e');
      return false;
    }
  }
}
