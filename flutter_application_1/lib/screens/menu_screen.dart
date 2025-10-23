import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../services/menu_service.dart';
import '../widgets/flexible_image.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  // Colores de la paleta
  final Color colorTexto = const Color.fromARGB(255, 0, 0, 0);
  final Color colorFondo = const Color.fromARGB(255, 255, 255, 255);
  final Color colorPrimario = const Color.fromRGBO(0, 20, 34, 1);

  // Lista de platillos registrados
  List<Map<String, dynamic>> _platillos = [];

  @override
  void initState() {
    super.initState();
    _fetchPlatillos();
  }

  Future<void> _fetchPlatillos() async {
    try {
      final platillos = await MenuService.getMenuItems();
      print('Datos obtenidos de la API: $platillos'); // Log para depuración
      setState(() {
        _platillos = List<Map<String, dynamic>>.from(platillos);
      });
      print(
        'Datos procesados para visualización: $_platillos',
      ); // Log para depuración
    } catch (e) {
      print('Error al obtener o procesar los datos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFondo,
      appBar: AppBar(
        title: const Text('Gestión de Menú'),
        backgroundColor: colorPrimario,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título
            Text(
              'Administrar Platillos del Menú',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorPrimario,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Botón para agregar platillo
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colorPrimario.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  _mostrarFormularioPlatilloAdmin(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimario,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restaurant_menu, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text(
                      'Agregar Nuevo Platillo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Título de los platillos
            Text(
              'Platillos Registrados',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorPrimario,
              ),
            ),
            const SizedBox(height: 12),

            // Lista de platillos en cards
            Expanded(
              child: _platillos.isEmpty
                  ? Center(
                      child: Text(
                        'No hay platillos disponibles.',
                        style: TextStyle(fontSize: 16, color: colorPrimario),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _platillos.length,
                      itemBuilder: (context, index) {
                        final platillo = _platillos[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text(
                                    'Platillo: ${platillo['Platillo'] ?? 'Sin nombre'}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: colorTexto,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Precio: ${platillo['Precio']?.toString() ?? '0.00'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Descripción: ${platillo['Descripcion'] ?? 'Sin descripción'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colorTexto.withOpacity(0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Estado: ${platillo['ID_Estado'] == 2 ? 'Disponible' : 'No Disponible'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colorTexto,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Categoría: ${platillo['CategoriaDescripcion'] ?? 'Sin categoría'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colorTexto,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarFormularioPlatilloAdmin(BuildContext context) {
    // Copiado/adaptado del modal de empleado (bottom-sheet con selector de imagen)
    const Color _modalPrimary = Color.fromRGBO(0, 20, 34, 1);
    final TextEditingController nombreController = TextEditingController();
    final TextEditingController precioController = TextEditingController();
    final TextEditingController descripcionController = TextEditingController();
    final TextEditingController imagenController = TextEditingController();
    Uint8List? imagenBytes;
    String? imagenFilename;
    final ImagePicker _picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Text(
                      'Agregar Nuevo Platillo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _modalPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nombreController,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        hintText: 'Nombre del platillo',
                        hintStyle: TextStyle(
                          color: Colors.black.withOpacity(0.6),
                        ),
                        prefixIcon: Icon(
                          Icons.restaurant_menu,
                          color: _modalPrimary,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.blueAccent,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _modalPrimary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final XFile? picked = await _picker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 85,
                              );
                              if (picked != null) {
                                imagenBytes = await picked.readAsBytes();
                                imagenFilename = picked.name;
                                imagenController.text = '';
                                setState(() {});
                              }
                            },
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Seleccionar imagen'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _modalPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.link),
                          color: _modalPrimary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: imagenController,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        hintText:
                            'Imagen (URL, opcional si eliges archivo local)',
                        prefixIcon: Icon(Icons.image, color: _modalPrimary),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _modalPrimary,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _modalPrimary,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (v) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    if (imagenBytes != null)
                      Container(
                        height: 140,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(imagenBytes!, fit: BoxFit.cover),
                        ),
                      )
                    else if (imagenController.text.trim().isNotEmpty)
                      Container(
                        height: 140,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FlexibleImage(
                            source: imagenController.text,
                            name: nombreController.text,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    TextField(
                      controller: precioController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        hintText: 'Precio (ej: 12.99)',
                        hintStyle: TextStyle(
                          color: Colors.black.withOpacity(0.6),
                        ),
                        prefixIcon: Icon(
                          Icons.attach_money,
                          color: Colors.green.shade600,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _modalPrimary,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _modalPrimary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descripcionController,
                      maxLines: 3,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        hintText: 'Descripción del platillo',
                        hintStyle: TextStyle(
                          color: Colors.black.withOpacity(0.6),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _modalPrimary,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _modalPrimary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          bool success = false;
                          if (imagenBytes != null) {
                            success = await MenuService.addMenuItemWithImage(
                              {
                                'Platillo': nombreController.text,
                                'Precio': precioController.text,
                                'Descripcion': descripcionController.text,
                              },
                              imageBytes: imagenBytes,
                              imageFilename: imagenFilename ?? 'imagen.jpg',
                            );
                          } else {
                            success = await MenuService.addMenuItem({
                              'Platillo': nombreController.text,
                              'Precio': precioController.text,
                              'Descripcion': descripcionController.text,
                              'Imagen': imagenController.text,
                            });
                          }
                          if (success) {
                            Navigator.of(context).pop();
                            _fetchPlatillos();
                          } else {
                            throw Exception('Error al guardar el platillo');
                          }
                        } catch (e) {
                          print('Error: $e');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _modalPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Guardar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
