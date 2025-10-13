import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../services/restaurante_service.dart';

class EmpresaScreen extends StatefulWidget {
  const EmpresaScreen({super.key});

  @override
  State<EmpresaScreen> createState() => _EmpresaScreenState();
}

class _EmpresaScreenState extends State<EmpresaScreen> {
  // Colores de la paleta
  final Color colorTexto = const Color.fromARGB(255, 0, 0, 0);
  final Color colorFondo = const Color.fromARGB(255, 255, 255, 255);
  final Color colorPrimario = const Color.fromRGBO(0, 20, 34, 1);

  // Variables para el logo
  Uint8List? _logoBytes;
  String? _logoPath;
  final ImagePicker _picker = ImagePicker();
  // Controllers para los campos del formulario
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _telefonoCtrl = TextEditingController();
  final TextEditingController _correoCtrl = TextEditingController();
  final TextEditingController _direccionCtrl = TextEditingController();
  String? _restauranteId;
  String? _debugApiResponse;

  // Función para seleccionar imagen
  Future<void> _seleccionarLogo() async {
    try {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Galería'),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? image = await _picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1000,
                      maxHeight: 1000,
                      imageQuality: 85,
                    );
                    if (image != null) {
                      final bytes = await image.readAsBytes();
                      setState(() {
                        _logoBytes = bytes;
                      });
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Cámara'),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? image = await _picker.pickImage(
                      source: ImageSource.camera,
                      maxWidth: 1000,
                      maxHeight: 1000,
                      imageQuality: 85,
                    );
                    if (image != null) {
                      final bytes = await image.readAsBytes();
                      setState(() {
                        _logoBytes = bytes;
                      });
                    }
                  },
                ),
                if (_logoBytes != null)
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text('Eliminar logo'),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _logoBytes = null;
                      });
                    },
                  ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFondo,
      appBar: AppBar(
        title: const Text('Información de la Empresa'),
        backgroundColor: colorPrimario,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Estado de diagnóstico
              if (_restauranteId == null)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.yellow[100],
                  child: const Text('Diagnóstico: no se ha cargado información del restaurante. Verifica la API.'),
                ),
              if (_debugApiResponse != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.grey[200],
                  child: SelectableText('API response / error: $_debugApiResponse'),
                ),
              ],
              Text(
                'Configuración de la Empresa',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorPrimario,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Campo Nombre de la Empresa
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colorPrimario.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _nombreCtrl,
                  style: TextStyle(color: colorTexto),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Nombre de la empresa',
                    hintStyle: TextStyle(color: colorTexto.withOpacity(0.6)),
                    prefixIcon: Icon(Icons.business, color: colorPrimario),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: colorPrimario, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: colorPrimario, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Campo Teléfono
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colorPrimario.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: colorTexto),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Teléfono',
                    hintStyle: TextStyle(color: colorTexto.withOpacity(0.6)),
                    prefixIcon: Icon(Icons.phone, color: colorPrimario),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: colorPrimario, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: colorPrimario, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Campo Correo
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colorPrimario.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _correoCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: colorTexto),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Correo electrónico',
                    hintStyle: TextStyle(color: colorTexto.withOpacity(0.6)),
                    prefixIcon: Icon(Icons.email, color: colorPrimario),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: colorPrimario, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: colorPrimario, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Campo Dirección
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colorPrimario.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _direccionCtrl,
                  maxLines: 3,
                  style: TextStyle(color: colorTexto),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Dirección de la empresa',
                    hintStyle: TextStyle(color: colorTexto.withOpacity(0.6)),
                    prefixIcon: Icon(Icons.location_on, color: colorPrimario),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: colorPrimario, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: colorPrimario, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Sección Logo
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: colorPrimario.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                         // Mostrar logo seleccionado (bytes) o logo desde ruta pública, o ícono placeholder
                        Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorPrimario.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                           child: _logoBytes != null
                               ? ClipRRect(
                                   borderRadius: BorderRadius.circular(10),
                                   child: Image.memory(
                                     _logoBytes!,
                                     fit: BoxFit.cover,
                                   ),
                                 )
                               : (_logoPath != null && _logoPath!.isNotEmpty)
                                   ? ClipRRect(
                                       borderRadius: BorderRadius.circular(10),
                                       child: Image.network(
                                         _logoPath!.startsWith('http') ? _logoPath! : 'http://192.168.10.125' + _logoPath!,
                                         fit: BoxFit.cover,
                                         errorBuilder: (c, e, s) => Icon(Icons.broken_image, color: colorPrimario.withOpacity(0.6)),
                                       ),
                                     )
                                   : Icon(
                                       Icons.image,
                                       size: 48,
                                       color: colorPrimario.withOpacity(0.6),
                                     ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _logoBytes != null ? 'Logo Seleccionado' : 'Logo de la Empresa',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorTexto,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _logoBytes != null
                              ? 'Toca el botón para cambiar el logo'
                              : 'Selecciona un logo para tu empresa',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorTexto.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _seleccionarLogo,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorPrimario,
                            side: BorderSide(color: colorPrimario, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _logoBytes != null ? Icons.edit : Icons.upload,
                                color: colorPrimario,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _logoBytes != null
                                    ? 'Cambiar Logo'
                                    : 'Seleccionar Logo',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Botón Guardar
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colorPrimario.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    // Construir body para enviar a la API
                    final body = {
                      'id': _restauranteId ?? '',
                      'nombre': _nombreCtrl.text.trim(),
                      'direccion': _direccionCtrl.text.trim(),
                      'telefono': _telefonoCtrl.text.trim(),
                      'correo': _correoCtrl.text.trim(),
                      'logo': '',
                    };

                    if (_logoBytes != null) {
                      // Enviar logo como base64 (por simplicidad). En producción preferir multipart.
                      body['logo'] = base64Encode(_logoBytes!);
                    }

                    // Validación en cliente: nombre es obligatorio
                    if (_nombreCtrl.text.trim().isEmpty) {
                      setState(() { _debugApiResponse = 'validation: Nombre requerido'; });
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nombre requerido')));
                      return;
                    }

                    // Si no existe id, crear; si existe, actualizar
                    Map<String, dynamic> resp;
                    try {
                      if (body['id'] == null || (body['id'] as String).isEmpty) {
                        resp = await RestauranteService.createRestaurante(body);
                      } else {
                        resp = await RestauranteService.updateRestaurante(body);
                      }
                      setState(() {
                        _debugApiResponse = resp.toString();
                      });
                      if (resp['success'] == true) {
                        // Recargar datos actualizados
                        await _cargarEmpresa();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Información guardada')));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp['message']?.toString() ?? 'Error')));
                      }
                    } catch (e) {
                      setState(() { _debugApiResponse = e.toString(); });
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error guardando: $e')));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorPrimario,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Guardar Información',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _cargarEmpresa();
  }

  Future<void> _cargarEmpresa() async {
    try {
      final data = await RestauranteService.getRestaurantes();
      setState(() {
        _debugApiResponse = null;
      });
      if (data.isNotEmpty) {
        final r = data[0];
        setState(() {
          _restauranteId = (r['Restaurante_ID'] ?? r['id']).toString();
          _nombreCtrl.text = (r['Nombre'] ?? r['nombre'] ?? '').toString();
          _telefonoCtrl.text = (r['Telefono'] ?? r['telefono'] ?? '').toString();
          _correoCtrl.text = (r['Correo'] ?? r['correo'] ?? '').toString();
          _direccionCtrl.text = (r['Direccion'] ?? r['direccion'] ?? '').toString();
           final logoVal = (r['Logo'] ?? r['logo'] ?? '').toString();
           // Si el logo es una ruta (comienza con / o http), guardamos la ruta en _logo (cadena)
           // Sólo usamos _logoBytes si el usuario seleccionó una imagen localmente.
           if (logoVal.isNotEmpty) {
             if (logoVal.startsWith('/') || logoVal.startsWith('http')) {
               // Guardamos la ruta como string en _logoBytes = null (la vista usará la ruta)
               _logoBytes = null;
               // También guardamos la ruta en una propiedad temporal para mostrar network image
               // (usamos la variable _debugApiResponse para debugging; no es ideal — si quieres podemos añadir _logoPath)
               // Para mejor soporte, añadiremos _logoPath
               _logoPath = logoVal;
             } else {
               try {
                 _logoBytes = base64Decode(logoVal);
                 _logoPath = null;
               } catch (_) {
                 _logoBytes = null;
                 _logoPath = null;
               }
             }
           }
        });
      }
    } catch (e) {
      setState(() {
        _debugApiResponse = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _correoCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }
}
