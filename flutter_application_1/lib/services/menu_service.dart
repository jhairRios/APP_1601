import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'api_config.dart';
import 'package:http_parser/http_parser.dart';

class MenuService {
  static const String _baseUrl = API_BASE_URL;
  // Stream broadcast para notificar cambios en el menú (add/update/delete)
  static final StreamController<bool> menuChangeController = StreamController<bool>.broadcast();

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
      print('=== addMenuItem ===');
      print('Enviando datos: $menuItem');
      
      final response = await http.post(
        Uri.parse('$_baseUrl?action=add_menu_item'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(menuItem),
      );
      
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          final decoded = json.decode(response.body);
          print('Decoded response: $decoded');
          
          if (decoded is Map && decoded['success'] == true) {
            print('✓ Platillo agregado exitosamente');
            // Notificar cambio
            try {
              menuChangeController.add(true);
            } catch (_) {}
            return true;
          }
          print('✗ Error en respuesta: $decoded');
          return false;
        } catch (e) {
          print('✗ Error al decodificar JSON: $e');
          return false;
        }
      } else {
        print('✗ Error HTTP: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('✗ Exception en addMenuItem: $e');
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
      print('Response addMenuItemWithImage: ${streamed.statusCode} - $respStr');
      if (streamed.statusCode == 200) {
        try {
          final decoded = json.decode(respStr);
          if (decoded is Map && decoded['success'] == true) {
            try {
              menuChangeController.add(true);
            } catch (_) {}
            return true;
          }
          print('Error en respuesta: $decoded');
          return false;
        } catch (e) {
          print('Error decodificando respuesta: $e');
          return false;
        }
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

  /// Actualiza un platillo existente (sin imagen).
  static Future<bool> updateMenuItem(Map<String, dynamic> menuItem) async {
    try {
      print('=== updateMenuItem ===');
      print('Enviando datos: $menuItem');
      
      final response = await http.post(
        Uri.parse('$_baseUrl?action=update_menu_item'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(menuItem),
      );
      
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          final decoded = json.decode(response.body);
          print('Decoded response: $decoded');
          
          if (decoded is Map && decoded['success'] == true) {
            print('✓ Platillo actualizado exitosamente');
            try {
              menuChangeController.add(true);
            } catch (_) {}
            return true;
          }
          print('✗ Error en respuesta: $decoded');
          return false;
        } catch (e) {
          print('✗ Error al decodificar JSON: $e');
          return false;
        }
      } else {
        print('✗ Error HTTP: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('✗ Exception en updateMenuItem: $e');
      return false;
    }
  }

  /// Actualiza un platillo con posibilidad de enviar imagen como bytes (multipart).
  /// Si [imageBytes] es null, se usa el método JSON simple.
  static Future<bool> updateMenuItemWithImage(
    Map<String, dynamic> menuItem, {
    Uint8List? imageBytes,
    String imageFilename = 'imagen.jpg',
  }) async {
    try {
      if (imageBytes == null) {
        return await updateMenuItem(menuItem);
      }
      final uri = Uri.parse('$_baseUrl?action=update_menu_item');
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
      print('Response updateMenuItemWithImage: ${streamed.statusCode} - $respStr');
      if (streamed.statusCode == 200) {
        try {
          final decoded = json.decode(respStr);
          if (decoded is Map && decoded['success'] == true) {
            try {
              menuChangeController.add(true);
            } catch (_) {}
            return true;
          }
          print('Error en respuesta: $decoded');
          return false;
        } catch (e) {
          print('Error decodificando respuesta: $e');
          return false;
        }
      }
      print(
        'Error multipart updateMenuItemWithImage: ${streamed.statusCode} -> $respStr',
      );
      return false;
    } catch (e) {
      print('Error en updateMenuItemWithImage: $e');
      return false;
    }
  }

  /// Elimina un platillo por su ID.
  static Future<bool> deleteMenuItem(int idMenu) async {
    try {
      print('=== deleteMenuItem ===');
      print('ID a eliminar: $idMenu');
      
      final response = await http.post(
        Uri.parse('$_baseUrl?action=delete_menu_item'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'ID_Menu': idMenu}),
      );
      
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          final decoded = json.decode(response.body);
          print('Decoded response: $decoded');
          
          if (decoded is Map && decoded['success'] == true) {
            print('✓ Platillo eliminado exitosamente');
            try {
              menuChangeController.add(true);
            } catch (_) {}
            return true;
          }
          print('✗ Error en respuesta: $decoded');
          return false;
        } catch (e) {
          print('✗ Error al decodificar JSON: $e');
          return false;
        }
      } else {
        print('✗ Error HTTP: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('✗ Exception en deleteMenuItem: $e');
      return false;
    }
  }
}
