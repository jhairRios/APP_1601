import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class RestauranteService {
  // Base URL dinámico: en web usamos el origen actual (permite localhost dev),
  // en dispositivos usamos la IP de la máquina de desarrollo.
  // Usar la IP de la máquina de desarrollo siemprge (evita que en web se solicite el index.html)
  static const String _baseUrl = 'http://localhost/Aplicacion_1/APP1601/APP_1601/flutter_application_1/php/api.php';

  static Future<List<Map<String, dynamic>>> getRestaurantes() async {
    final response = await http.get(Uri.parse('$_baseUrl?action=get_restaurantes'));
    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['restaurantes']);
        }
        throw Exception('API returned error: ' + response.body);
      } catch (e) {
        throw Exception('Invalid JSON from API: ${response.body}');
      }
    }
    throw Exception('HTTP ${response.statusCode}: ${response.body}');
  }

  static Future<Map<String, dynamic>> getRestaurante(String id) async {
    final response = await http.get(Uri.parse('$_baseUrl?action=get_restaurante&id=$id'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data;
    }
    throw Exception('Error obteniendo restaurante');
  }

  static Future<Map<String, dynamic>> createRestaurante(Map<String, dynamic> body) async {
    // Si body contiene 'logo_bytes' con a File path local (bytes), enviamos multipart
    if (body.containsKey('logo_bytes') && body['logo_bytes'] != null) {
      // logo_bytes expected as Uint8List
      var uri = Uri.parse(_baseUrl + '?action=create_restaurante');
      var req = http.MultipartRequest('POST', uri);
      req.fields['nombre'] = body['nombre'] ?? '';
      req.fields['direccion'] = body['direccion'] ?? '';
      req.fields['telefono'] = body['telefono'] ?? '';
      req.fields['correo'] = body['correo'] ?? '';
      var bytes = body['logo_bytes'];
      req.files.add(http.MultipartFile.fromBytes('logo_file', bytes, filename: 'logo.png', contentType: MediaType('image', 'png')));
      var streamed = await req.send();
      var respStr = await streamed.stream.bytesToString();
      return jsonDecode(respStr);
    } else {
      final response = await http.post(Uri.parse(_baseUrl), body: {...body, 'action': 'create_restaurante'});
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': 'Error creando restaurante'};
    }
  }

  static Future<Map<String, dynamic>> updateRestaurante(Map<String, dynamic> body) async {
    if (body.containsKey('logo_bytes') && body['logo_bytes'] != null) {
      var uri = Uri.parse(_baseUrl + '?action=update_restaurante');
      var req = http.MultipartRequest('POST', uri);
      req.fields['id'] = body['id'].toString();
      req.fields['nombre'] = body['nombre'] ?? '';
      req.fields['direccion'] = body['direccion'] ?? '';
      req.fields['telefono'] = body['telefono'] ?? '';
      req.fields['correo'] = body['correo'] ?? '';
      var bytes = body['logo_bytes'];
      req.files.add(http.MultipartFile.fromBytes('logo_file', bytes, filename: 'logo.png', contentType: MediaType('image', 'png')));
      var streamed = await req.send();
      var respStr = await streamed.stream.bytesToString();
      return jsonDecode(respStr);
    } else {
      final response = await http.post(Uri.parse(_baseUrl), body: {...body, 'action': 'update_restaurante'});
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': 'Error actualizando restaurante'};
    }
  }

  static Future<Map<String, dynamic>> deleteRestaurante(String id) async {
    final response = await http.post(Uri.parse(_baseUrl), body: {'action': 'delete_restaurante', 'id': id});
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return {'success': false, 'message': 'Error eliminando restaurante'};
  }
}
