import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import '../services/menu_service.dart';
import '../widgets/flexible_image.dart';
import '../widgets/product_image_box.dart';

class EmpleadoScreen extends StatefulWidget {
  const EmpleadoScreen({Key? key}) : super(key: key);

  @override
  State<EmpleadoScreen> createState() => _EmpleadoScreenState();
}

class _EmpleadoScreenState extends State<EmpleadoScreen> {
  // Devuelve el estado textual del platillo según el ID_Estado
  /// Devuelve el estado textual del platillo según el ID_Estado de la BD
  /// 2 = Disponible, 1 = No Disponible
  String _estadoPlatillo(dynamic estado) {
    if (estado == 2) {
      return 'Disponible';
    }
    return 'No Disponible';
  }

  // Devuelve el estado textual del platillo según el ID_Estado

  List<Map<String, dynamic>> categorias = <Map<String, dynamic>>[];
  int? categoriaSeleccionada;
  int? estadoSeleccionado;
  int _selectedIndex = 0;
  List<dynamic> _menuItems = [];
  late StreamSubscription<bool> _menuSubscription;

  @override
  void initState() {
    super.initState();
    _fetchCategorias();
    _fetchMenuItems();
    // Suscribirse a cambios en el menú para refrescar automáticamente
    _menuSubscription = MenuService.menuChangeController.stream.listen((_) {
      _fetchMenuItems();
    });
  }

  @override
  void dispose() {
    try {
      _menuSubscription.cancel();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _fetchCategorias() async {
    try {
      final lista = await MenuService.getCategorias();
      setState(() {
        categorias = List<Map<String, dynamic>>.from(lista);
      });
      // Si no hay selección previa, usar la primera categoría disponible
      if (categoriaSeleccionada == null && categorias.isNotEmpty) {
        final firstId = categorias.first['ID_Categoria'];
        categoriaSeleccionada = firstId is int
            ? firstId
            : int.tryParse(firstId.toString());
      }
    } catch (e) {
      print('Error en _fetchCategorias: $e');
      setState(() {
        categorias = <Map<String, dynamic>>[];
      });
    }
  }

  Future<void> _fetchMenuItems() async {
    try {
      final items = await MenuService.getMenuItems();
      setState(() {
        _menuItems = items;
      });
    } catch (e) {
      print('Error fetching menu items: $e');
    }
  }

  // ✅ MOSTRAR OPCIONES AL TOCAR UN PLATILLO
  void _mostrarOpcionesPlatillo(
    BuildContext context,
    Map<String, dynamic> platillo,
    Color colorPrimario,
    Color colorAccento,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Título
              Text(
                platillo['Platillo'] ?? 'Platillo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorPrimario,
                ),
              ),
              const SizedBox(height: 20),
              // Opciones
              ListTile(
                leading: Icon(Icons.visibility, color: Colors.blue),
                title: const Text('Ver Detalles'),
                onTap: () {
                  Navigator.pop(context);
                  _mostrarDetallesPlatillo(context, platillo, colorPrimario);
                },
              ),
              ListTile(
                leading: Icon(Icons.edit, color: Colors.orange),
                title: const Text('Editar Platillo'),
                onTap: () {
                  Navigator.pop(context);
                  _mostrarFormularioEditarPlatillo(
                    context,
                    platillo,
                    colorPrimario,
                    colorAccento,
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar Platillo'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmarEliminarPlatillo(context, platillo, colorPrimario);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // ✅ MOSTRAR DETALLES DEL PLATILLO
  void _mostrarDetallesPlatillo(
    BuildContext context,
    Map<String, dynamic> platillo,
    Color colorPrimario,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen
                if (platillo['Imagen'] != null &&
                    platillo['Imagen'].toString().isNotEmpty)
                  ProductImageBox(
                    source: platillo['Imagen'],
                    name: platillo['Platillo'] ?? '',
                    borderRadius: 12,
                    height: 200,
                  ),
                const SizedBox(height: 16),
                // Nombre
                Text(
                  platillo['Platillo'] ?? 'Sin nombre',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorPrimario,
                  ),
                ),
                const SizedBox(height: 8),
                // Precio
                Text(
                  '\$${platillo['Precio'] ?? '0'}',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                // Descripción
                Text(
                  platillo['Descripcion'] ?? 'Sin descripción',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                // Estado
                Row(
                  children: [
                    Text(
                      'Estado: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorPrimario,
                      ),
                    ),
                    Text(
                      _estadoPlatillo(platillo['ID_Estado']),
                      style: TextStyle(
                        color: platillo['ID_Estado'] == 2
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Botón cerrar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorPrimario,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ FORMULARIO PARA EDITAR PLATILLO
  void _mostrarFormularioEditarPlatillo(
    BuildContext context,
    Map<String, dynamic> platillo,
    Color colorPrimario,
    Color colorAccento,
  ) {
    final TextEditingController nombreController =
        TextEditingController(text: platillo['Platillo']?.toString() ?? '');
    final TextEditingController precioController =
        TextEditingController(text: platillo['Precio']?.toString() ?? '');
    final TextEditingController descripcionController =
        TextEditingController(text: platillo['Descripcion']?.toString() ?? '');
    final TextEditingController imagenController =
        TextEditingController(text: platillo['Imagen']?.toString() ?? '');

    // Variables para imagen local
    Uint8List? imagenBytes;
    String? imagenFilename;
    final ImagePicker _picker = ImagePicker();

    // Convertir IDs a int si vienen como String
    int? categoriaActual = platillo['ID_Categoria'] is int
        ? platillo['ID_Categoria']
        : int.tryParse(platillo['ID_Categoria']?.toString() ?? '');

    int? estadoActual = platillo['ID_Estado'] is int
        ? platillo['ID_Estado']
        : int.tryParse(platillo['ID_Estado']?.toString() ?? '');

    // Normalizar valores iniciales como en admin
    if ((categoriaActual == null ||
            !(categorias.any((cat) {
              final id = cat['ID_Categoria'];
              final intId = id is int ? id : int.tryParse(id.toString());
              return intId == categoriaActual;
            }))) &&
        categorias.isNotEmpty) {
      final firstId = categorias.first['ID_Categoria'];
      categoriaActual =
          firstId is int ? firstId : int.tryParse(firstId.toString());
    }

    if (estadoActual != 1 && estadoActual != 2) {
      estadoActual = 2;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Handle
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
                        // Título
                        Text(
                          'Editar Platillo',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorPrimario,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        // Campo Nombre
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
                              color: colorPrimario,
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
                                color: colorPrimario,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Botón seleccionar imagen
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final XFile? picked =
                                      await _picker.pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 85,
                                  );
                                  if (picked != null) {
                                    final bytes = await picked.readAsBytes();
                                    setModalState(() {
                                      imagenBytes = bytes;
                                      imagenFilename = picked.name;
                                      imagenController.text = '';
                                    });
                                  }
                                },
                                icon: const Icon(Icons.photo_library),
                                label: const Text('Cambiar imagen'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorPrimario,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Campo URL imagen
                        TextField(
                          controller: imagenController,
                          style: TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            hintText: 'URL de imagen (opcional)',
                            prefixIcon:
                                Icon(Icons.image, color: colorPrimario),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorPrimario,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorPrimario,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (v) {
                            setModalState(() {});
                          },
                        ),
                        const SizedBox(height: 12),
                        // Preview imagen
                        if (imagenBytes != null)
                          ProductImageBox(
                            bytes: imagenBytes,
                            name: nombreController.text,
                            borderRadius: 12,
                            height: 140,
                          )
                        else if (imagenController.text.trim().isNotEmpty)
                          ProductImageBox(
                            source: imagenController.text,
                            name: nombreController.text,
                            borderRadius: 12,
                            height: 140,
                          ),
                        // Campo Precio
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
                                color: colorPrimario,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorPrimario,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Campo Descripción
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
                                color: colorPrimario,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorPrimario,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Dropdown Categoría
                        DropdownButtonFormField<int>(
                          value: categorias.any((cat) {
                            final id = cat['ID_Categoria'];
                            final catId = id is int ? id : int.tryParse(id.toString());
                            return catId == categoriaActual;
                          }) ? categoriaActual : null,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            labelText: 'Categoría',
                            hintText: 'Seleccionar Categoría',
                            hintStyle: TextStyle(
                              color: Colors.black.withOpacity(0.6),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorPrimario,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorPrimario,
                                width: 2,
                              ),
                            ),
                          ),
                          items: categorias
                              .where(
                                (cat) =>
                                    cat['ID_Categoria'] != null &&
                                    cat['Descripcion'] != null,
                              )
                              .map((cat) {
                                final id = cat['ID_Categoria'];
                                final catId = id is int
                                    ? id
                                    : int.tryParse(id.toString());
                                return DropdownMenuItem<int>(
                                  value: catId,
                                  child: Text(cat['Descripcion'].toString()),
                                );
                              })
                              .toList(),
                          onChanged: (value) {
                            setModalState(() {
                              categoriaActual = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        // Dropdown Estado
                        DropdownButtonFormField<int>(
                          value: (estadoActual == 1 || estadoActual == 2)
                              ? estadoActual
                              : null,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            labelText: 'Estado',
                            hintText: 'Seleccionar Estado',
                            hintStyle: TextStyle(
                              color: Colors.black.withOpacity(0.6),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorPrimario,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorPrimario,
                                width: 2,
                              ),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 1,
                              child: Text('No Disponible'),
                            ),
                            DropdownMenuItem(
                              value: 2,
                              child: Text('Disponible'),
                            ),
                          ],
                          onChanged: (value) {
                            setModalState(() {
                              estadoActual = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        // Botón Actualizar
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              // Convertir ID_Menu a int
                              final idMenu = platillo['ID_Menu'] is int
                                  ? platillo['ID_Menu']
                                  : int.tryParse(
                                      platillo['ID_Menu']?.toString() ?? '0',
                                    );

                              print(
                                '🔄 Actualizando platillo ID: $idMenu',
                              );

                              Map<String, dynamic> datosActualizados = {
                                'ID_Menu': idMenu,
                                'Platillo': nombreController.text.trim(),
                                'Precio': precioController.text.trim(),
                                'Descripcion':
                                    descripcionController.text.trim(),
                                'ID_Categoria': categoriaActual,
                                'ID_Estado': estadoActual,
                              };

                              // Solo incluir Imagen si cambió y no está vacía
                              final nuevaImagen =
                                  imagenController.text.trim();
                              if (nuevaImagen.isNotEmpty &&
                                  nuevaImagen != platillo['Imagen']) {
                                datosActualizados['Imagen'] = nuevaImagen;
                              }

                              print('📤 Datos a enviar: $datosActualizados');

                              bool success = false;
                              if (imagenBytes != null) {
                                // Actualizar con imagen nueva
                                success =
                                    await MenuService.updateMenuItemWithImage(
                                  datosActualizados,
                                  imageBytes: imagenBytes,
                                  imageFilename:
                                      imagenFilename ?? 'imagen.jpg',
                                );
                              } else {
                                // Actualizar sin cambiar imagen
                                success = await MenuService.updateMenuItem(
                                  datosActualizados,
                                );
                              }

                              if (success) {
                                print('✅ Platillo actualizado exitosamente');
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '✓ Platillo actualizado exitosamente',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  _fetchMenuItems();
                                }
                              } else {
                                throw Exception(
                                  'Error al actualizar el platillo',
                                );
                              }
                            } catch (e) {
                              print('❌ Error al actualizar: $e');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorPrimario,
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
                            'Actualizar',
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
      },
    );
  }

  // ✅ CONFIRMAR ELIMINACIÓN DE PLATILLO
  void _confirmarEliminarPlatillo(
    BuildContext context,
    Map<String, dynamic> platillo,
    Color colorPrimario,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            '¿Eliminar platillo?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorPrimario,
            ),
          ),
          content: Text(
            '¿Estás seguro de que deseas eliminar "${platillo['Platillo']}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Convertir ID_Menu a int
                  final idMenu = platillo['ID_Menu'] is int
                      ? platillo['ID_Menu']
                      : int.tryParse(platillo['ID_Menu']?.toString() ?? '0');

                  print('🗑️ Eliminando platillo ID: $idMenu');

                  final success =
                      await MenuService.deleteMenuItem(idMenu ?? 0);

                  if (success) {
                    print('✅ Platillo eliminado exitosamente');
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Platillo eliminado'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _fetchMenuItems();
                    }
                  } else {
                    throw Exception('Error al eliminar');
                  }
                } catch (e) {
                  print('❌ Error: $e');
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }


  void _mostrarFormularioPlatilloEmpleado(BuildContext context) {
    // Usar el color primario de la app para los modales
    const Color _modalPrimary = Color.fromRGBO(0, 20, 34, 1);
    final TextEditingController nombreController = TextEditingController();
    final TextEditingController precioController = TextEditingController();
    final TextEditingController descripcionController = TextEditingController();
    // Controller para la imagen (URL o ruta)
    final TextEditingController imagenController = TextEditingController();
    // Para seleccionar imagen desde dispositivo
    Uint8List? imagenBytes;
    String? imagenFilename;
    final ImagePicker _picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        // Estados locales del modal
        int? selectedCategoriaId = categoriaSeleccionada;
        int selectedEstadoId = estadoSeleccionado ?? 2;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // Asegurar defaults válidos
            if ((selectedCategoriaId == null ||
                    !(categorias.any((cat) {
                      final id = cat['ID_Categoria'];
                      final intId = id is int ? id : int.tryParse(id.toString());
                      return intId == selectedCategoriaId;
                    }))) &&
                categorias.isNotEmpty) {
              final firstId = categorias.first['ID_Categoria'];
              selectedCategoriaId = firstId is int
                  ? firstId
                  : int.tryParse(firstId.toString());
            }
            if (selectedEstadoId != 1 && selectedEstadoId != 2) {
              selectedEstadoId = 2;
            }
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
                    // handle
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
                    // Botón para seleccionar imagen desde el dispositivo
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
                                final b = await picked.readAsBytes();
                                setModalState(() {
                                  imagenBytes = b;
                                  imagenFilename = picked.name;
                                  // Limpiar campo URL si había
                                  imagenController.text = '';
                                });
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
                        // También permitir pegar URL manualmente si el usuario quiere
                        IconButton(
                          onPressed: () {
                            // foco al campo URL en caso de querer pegar
                            // No hacemos más aquí; el campo URL aún está presente más abajo
                          },
                          icon: const Icon(Icons.link),
                          color: _modalPrimary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Campo para la imagen (URL o ruta) - opcional
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
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    // Preview de la imagen: preferir bytes seleccionados, si no usar URL
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
                    // Selector de Categoría (estilo admin)
                    if (categorias.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _modalPrimary,
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: selectedCategoriaId,
                            isExpanded: true,
                            hint: Text(
                              'Seleccionar Categoría',
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.6),
                              ),
                            ),
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: _modalPrimary,
                            ),
                            items: categorias.map((cat) {
                              final id = cat['ID_Categoria'];
                              final intId =
                                  id is int ? id : int.tryParse(id.toString());
                              return DropdownMenuItem<int>(
                                value: intId,
                                child: Row(
                                  children: [
                                    Icon(Icons.category, color: _modalPrimary),
                                    const SizedBox(width: 8),
                                    Text(
                                      cat['Descripcion']?.toString() ?? '',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setModalState(() {
                                selectedCategoriaId = value;
                                categoriaSeleccionada = value;
                              });
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Selector de Estado (estilo admin)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _modalPrimary, width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedEstadoId,
                          isExpanded: true,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: _modalPrimary,
                          ),
                          items: const [
                            DropdownMenuItem<int>(
                              value: 2,
                              child: Text('Disponible'),
                            ),
                            DropdownMenuItem<int>(
                              value: 1,
                              child: Text('No Disponible'),
                            ),
                          ],
                          onChanged: (value) {
                            setModalState(() {
                              selectedEstadoId = value ?? 2;
                              estadoSeleccionado = selectedEstadoId;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          bool success = false;
                          if (imagenBytes != null) {
                            // enviar multipart con bytes
                            success = await MenuService.addMenuItemWithImage(
                              {
                                'Platillo': nombreController.text,
                                'Precio': precioController.text,
                                'Descripcion': descripcionController.text,
                                'ID_Categoria': selectedCategoriaId,
                                'ID_Estado': selectedEstadoId,
                              },
                              imageBytes: imagenBytes,
                              imageFilename: imagenFilename ?? 'imagen.jpg',
                            );
                          } else {
                            // enviar JSON, si el usuario pegó una URL se incluirá
                            success = await MenuService.addMenuItem({
                              'Platillo': nombreController.text,
                              'Precio': precioController.text,
                              'Descripcion': descripcionController.text,
                              'Imagen': imagenController.text,
                              'ID_Categoria': selectedCategoriaId,
                              'ID_Estado': selectedEstadoId,
                            });
                          }
                          if (success) {
                            Navigator.of(context).pop();
                            _fetchMenuItems();
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Paleta de colores
    const Color colorPrimario = Color.fromRGBO(0, 20, 34, 1);
    const Color colorFondo = Color.fromARGB(255, 248, 250, 252);
    const Color colorAccento = Color.fromARGB(255, 76, 175, 80);
    const Color colorNaranja = Color.fromARGB(255, 255, 152, 0);
    const Color colorAzul = Color.fromARGB(255, 33, 150, 243);

    return Scaffold(
      backgroundColor: colorFondo,
      appBar: AppBar(
        backgroundColor: colorPrimario,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            // Logo circular con borde elegante (igual que registro de usuario)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipOval(
                child: FlexibleImage(
                  source: 'assets/LogoPinequitas.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Panel de Empleado',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              // Mostrar perfil del empleado
            },
            icon: const Icon(Icons.account_circle),
          ),
          IconButton(
            onPressed: () {
              // Cerrar sesión
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboard(colorPrimario, colorAccento, colorNaranja, colorAzul),
          _buildGestionMenu(colorPrimario, colorAccento),
          _buildTomarPedidos(colorPrimario, colorNaranja),
          _buildAsignarRepartidor(colorPrimario, colorAzul),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: colorPrimario,
        unselectedItemColor: Colors.grey[600],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Menú',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Pedidos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.delivery_dining),
            label: 'Repartidores',
          ),
        ],
      ),
    );
  }

  // ✅ DASHBOARD PRINCIPAL
  Widget _buildDashboard(
    Color colorPrimario,
    Color colorAccento,
    Color colorNaranja,
    Color colorAzul,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bienvenida
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorPrimario, colorPrimario.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Bienvenido, Empleado!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Panel de control para gestión de pedidos',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Estadísticas rápidas
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Pedidos Hoy',
                  '24',
                  Icons.shopping_cart,
                  colorNaranja,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'En Proceso',
                  '8',
                  Icons.schedule,
                  colorAzul,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Completados',
                  '16',
                  Icons.check_circle,
                  colorAccento,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Accesos rápidos
          Text(
            'Accesos Rápidos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorPrimario,
            ),
          ),
          const SizedBox(height: 16),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildQuickActionCard(
                'Gestionar Menú',
                Icons.restaurant_menu,
                colorAccento,
                () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
              ),
              _buildQuickActionCard(
                'Nuevo Pedido',
                Icons.add_shopping_cart,
                colorNaranja,
                () {
                  setState(() {
                    _selectedIndex = 2;
                  });
                },
              ),
              _buildQuickActionCard(
                'Asignar Repartidor',
                Icons.delivery_dining,
                colorAzul,
                () {
                  setState(() {
                    _selectedIndex = 3;
                  });
                },
              ),
              _buildQuickActionCard(
                'Ver Reportes',
                Icons.analytics,
                colorPrimario,
                () {
                  // Navegar a reportes
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ GESTIÓN DE MENÚ
  Widget _buildGestionMenu(Color colorPrimario, Color colorAccento) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Text(
            'Gestión de Menú',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorPrimario,
            ),
          ),

          const SizedBox(height: 16),

          // Botón agregar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _mostrarFormularioPlatilloEmpleado(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorAccento,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Agregar Nuevo Platillo'),
            ),
          ),

          const SizedBox(height: 20),

          // Grid de platillos (estilo cliente)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: _menuItems.length,
            itemBuilder: (context, index) {
              final item = _menuItems[index];
              return _buildMenuItemCardEmpleado(
                item,
                colorPrimario,
                colorAccento,
                index,
              );
            },
          ),
        ],
      ),
    );
  }

  // Tarjeta de producto para la vista de empleado (basada en la de cliente)
  Widget _buildMenuItemCardEmpleado(
    Map<String, dynamic> item,
    Color colorPrimario,
    Color colorAccento,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        // Al tocar, mostrar opciones (Ver/Editar/Eliminar)
        _mostrarOpcionesPlatillo(context, item, colorPrimario, colorAccento);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Evitar overflow calculando alturas internas según el espacio disponible
          final double totalH =
              constraints.maxHeight; // altura disponible para la tarjeta
          // Reservar ~65% para la imagen y el resto para la info
          final double imageH = (totalH.isFinite && totalH > 0)
              ? totalH * 0.65
              : 140;
          final double infoH = (totalH.isFinite && totalH > 0)
              ? totalH - imageH
              : 60;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Imagen con altura fija relativa (estandarizada)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Container(
                    color: Colors.grey[200],
                    child: ProductImageBox(
                      source: item['Imagen'] ?? item['image'],
                      name: item['Platillo'] ?? item['name'],
                      height: imageH,
                      borderRadius: 0,
                    ),
                  ),
                ),

                // Información (nombre + precio) with limited height
                Container(
                  height: infoH,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item['Platillo'] ?? item['name'] ?? 'Sin nombre',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorPrimario,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '\$${(item['Precio'] ?? item['price'] ?? 0).toString()}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _estadoPlatillo(item['ID_Estado']),
                        style: TextStyle(
                          fontSize: 12,
                          color: item['ID_Estado'] == 2
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ✅ TOMAR PEDIDOS
  Widget _buildTomarPedidos(Color colorPrimario, Color colorNaranja) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Text(
            'Gestión de Pedidos',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorPrimario,
            ),
          ),

          const SizedBox(height: 16),

          // Botón nuevo pedido
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Crear nuevo pedido
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorNaranja,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Crear Nuevo Pedido'),
            ),
          ),

          const SizedBox(height: 20),

          // Filtros de estado con mejor scroll
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                _buildStatusChip('Todos', true, colorPrimario),
                const SizedBox(width: 8),
                _buildStatusChip('Pendientes', false, colorNaranja),
                const SizedBox(width: 8),
                _buildStatusChip('En Preparación', false, Colors.blue),
                const SizedBox(width: 8),
                _buildStatusChip('Listos', false, Colors.green),
                const SizedBox(width: 8),
                _buildStatusChip('En Entrega', false, Colors.purple),
                const SizedBox(width: 8),
                _buildStatusChip('Entregados', false, Colors.grey),
                const SizedBox(width: 8),
                _buildStatusChip('Cancelados', false, Colors.red),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Lista de pedidos
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            itemBuilder: (context, index) {
              return _buildOrderCard(
                'Pedido #${1000 + index}',
                'Cliente ${index + 1}',
                'Mesa ${index + 1}',
                _getOrderStatus(index),
                '\$${(index + 1) * 25}.00',
                colorPrimario,
                colorNaranja,
              );
            },
          ),
        ],
      ),
    );
  }

  // ✅ ASIGNAR REPARTIDOR
  Widget _buildAsignarRepartidor(Color colorPrimario, Color colorAzul) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Text(
            'Asignar Repartidores',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorPrimario,
            ),
          ),

          const SizedBox(height: 20),

          // Repartidores disponibles
          Text(
            'Repartidores Disponibles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorPrimario,
            ),
          ),
          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                _buildRepartidorCard('Juan Pérez', 'Disponible', colorAzul),
                _buildRepartidorCard('María García', 'En ruta', colorAzul),
                _buildRepartidorCard('Carlos López', 'Disponible', colorAzul),
                _buildRepartidorCard('Ana Martínez', 'En ruta', colorAzul),
                _buildRepartidorCard('Luis Rodríguez', 'Disponible', colorAzul),
                _buildRepartidorCard(
                  'Sofia Hernández',
                  'Disponible',
                  colorAzul,
                ),
                _buildRepartidorCard('Miguel Torres', 'En ruta', colorAzul),
                _buildRepartidorCard('Elena Vargas', 'Disponible', colorAzul),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Pedidos listos para entrega
          Text(
            'Pedidos Listos para Entrega',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorPrimario,
            ),
          ),
          const SizedBox(height: 12),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            itemBuilder: (context, index) {
              return _buildReadyOrderCard(
                'Pedido #${2000 + index}',
                'Dirección ${index + 1}',
                'Cliente ${index + 1}',
                '\$${(index + 1) * 30}.00',
                colorPrimario,
                colorAzul,
              );
            },
          ),
        ],
      ),
    );
  }

  // ✅ WIDGETS AUXILIARES
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, bool isSelected, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? color : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? color : Colors.grey[300]!),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Nota: en la vista de empleado, las tarjetas de platillos se generan
  // directamente desde la lista de _menuItems, por lo que no se necesita
  // este helper separado.

  Widget _buildOrderCard(
    String orderNumber,
    String customer,
    String table,
    String status,
    String total,
    Color colorPrimario,
    Color colorNaranja,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                orderNumber,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Cliente: $customer'),
          Text('Mesa: $table'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: $total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorNaranja,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // Ver detalles del pedido
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimario,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Ver Detalles'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRepartidorCard(String name, String status, Color colorAzul) {
    return Container(
      width: 140,
      height: 120,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colorAzul.withOpacity(0.1),
            child: Icon(Icons.person, color: colorAzul),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: status == 'Disponible'
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                color: status == 'Disponible' ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ), //hola
    ); //drgdrgdrsefsef
  }

  Widget _buildReadyOrderCard(
    String orderNumber,
    String address,
    String customer,
    String total,
    Color colorPrimario,
    Color colorAzul,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orderNumber,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('Cliente: $customer'),
                Text('Dirección: $address'),
                Text(
                  'Total: $total',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorAzul,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Asignar repartidor
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorAzul,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.assignment_ind, size: 16),
            label: const Text('Asignar'),
          ),
        ],
      ),
    );
  }

  String _getOrderStatus(int index) {
    final statuses = ['Pendiente', 'En Preparación', 'Listo', 'Entregado'];
    return statuses[index % statuses.length];
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pendiente':
        return Colors.orange;
      case 'En Preparación':
        return Colors.blue;
      case 'Listo':
        return Colors.green;
      case 'Entregado':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
