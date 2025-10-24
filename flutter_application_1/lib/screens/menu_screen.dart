import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:async';
import '../services/menu_service.dart';
import '../widgets/product_image_box.dart';
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
  List<Map<String, dynamic>> _categorias = [];
  late StreamSubscription<bool> _menuSubscription;

  @override
  void initState() {
    super.initState();
    _fetchPlatillos();
    _fetchCategorias();
    _menuSubscription = MenuService.menuChangeController.stream.listen((_) {
      _fetchPlatillos();
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
      final categorias = await MenuService.getCategorias();
      setState(() {
        _categorias = List<Map<String, dynamic>>.from(categorias);
      });
    } catch (e) {
      print('Error al obtener categorías: $e');
    }
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

  // Helper para mostrar el estado del platillo
  String _estadoPlatillo(dynamic estado) {
    if (estado == null) return 'Sin estado';
    if (estado == 2) return 'Disponible';
    if (estado == 1) return 'No Disponible';
    return 'Sin estado';
  }

  // Widget para construir la card de platillo (estilo empleado)
  Widget _buildMenuItemCard(Map<String, dynamic> item, int index) {
    return GestureDetector(
      onTap: () {
        _mostrarOpcionesPlatillo(context, item);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double totalH = constraints.maxHeight;
          final double imageH = (totalH.isFinite && totalH > 0)
              ? totalH * 0.65
              : 140;
      // Eliminamos alto fijo para la sección de información para evitar
      // pequeños desbordes por fracciones de pixel. Usaremos Expanded.

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Imagen del platillo en la card (estandarizada)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Container(
                    color: Colors.grey[200],
                    child: ProductImageBox(
                      source: item['Imagen'] ?? item['image'] ?? '',
                      name: item['Platillo'] ?? item['name'] ?? 'Sin nombre',
                      height: imageH,
                      borderRadius: 0, // ya aplicamos el redondeo externo
                    ),
                  ),
                ),

                // Información (usa Expanded para ocupar el espacio restante)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
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
                        const SizedBox(height: 4),
                        Text(
                          '\$${(item['Precio'] ?? item['price'] ?? 0).toString()}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Flexible(
                          child: Text(
                            _estadoPlatillo(item['ID_Estado']),
                            style: TextStyle(
                              fontSize: 12,
                              color: item['ID_Estado'] == 2
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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

            // Lista de platillos en cards (estilo Grid como empleado)
            Expanded(
              child: _platillos.isEmpty
                  ? Center(
                      child: Text(
                        'No hay platillos disponibles.',
                        style: TextStyle(fontSize: 16, color: colorPrimario),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: _platillos.length,
                      itemBuilder: (context, index) {
                        final platillo = _platillos[index];
                        return _buildMenuItemCard(platillo, index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Mostrar opciones para editar o eliminar un platillo
  void _mostrarOpcionesPlatillo(
    BuildContext context,
    Map<String, dynamic> platillo,
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
              Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Text(
                platillo['Platillo'] ?? 'Platillo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorPrimario,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.visibility, color: Colors.blue),
                title: const Text('Ver Detalles'),
                onTap: () {
                  Navigator.pop(context);
                  _mostrarDetallesPlatillo(context, platillo);
                },
              ),
              ListTile(
                leading: Icon(Icons.edit, color: colorPrimario),
                title: const Text('Editar Platillo'),
                onTap: () {
                  Navigator.pop(context);
                  _mostrarFormularioEditarPlatillo(context, platillo);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar Platillo'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmarEliminacion(context, platillo);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // Mostrar detalles completos del platillo
  void _mostrarDetallesPlatillo(
    BuildContext context,
    Map<String, dynamic> platillo,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 48,
                        height: 4,
                        margin: const EdgeInsets.only(top: 12, bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    // Imagen del platillo (estandarizada)
                    if (platillo['Imagen'] != null &&
                        platillo['Imagen'].toString().isNotEmpty)
                      Container(
                        height: 200,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ProductImageBox(
                          source: platillo['Imagen'].toString(),
                          name: platillo['Platillo']?.toString() ?? '',
                          borderRadius: 16,
                          height: 200,
                        ),
                      ),
                    const SizedBox(height: 20),
                    // Nombre del platillo
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        platillo['Platillo'] ?? 'Sin nombre',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorPrimario,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Precio
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            color: Colors.green.shade600,
                            size: 28,
                          ),
                          Text(
                            '${platillo['Precio']?.toString() ?? '0.00'}',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Descripción
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Descripción',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorPrimario,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            platillo['Descripcion'] ?? 'Sin descripción',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorTexto.withOpacity(0.8),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Categoría y Estado
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorPrimario.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Categoría',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorPrimario,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    platillo['CategoriaDescripcion'] ??
                                        'Sin categoría',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colorTexto,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: platillo['ID_Estado'] == 2
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Estado',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: platillo['ID_Estado'] == 2
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        platillo['ID_Estado'] == 2
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        size: 16,
                                        color: platillo['ID_Estado'] == 2
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        platillo['ID_Estado'] == 2
                                            ? 'Disponible'
                                            : 'No Disponible',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: colorTexto,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Botones de acción
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _mostrarFormularioEditarPlatillo(
                                  context,
                                  platillo,
                                );
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Editar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorPrimario,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _confirmarEliminacion(context, platillo);
                              },
                              icon: const Icon(Icons.delete),
                              label: const Text('Eliminar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Confirmar la eliminación del platillo
  void _confirmarEliminacion(
    BuildContext context,
    Map<String, dynamic> platillo,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text(
            '¿Estás seguro de que deseas eliminar "${platillo['Platillo']}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final idMenu = platillo['ID_Menu'];
                  if (idMenu != null) {
                    final success = await MenuService.deleteMenuItem(idMenu);
                    if (success) {
                      _fetchPlatillos();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Platillo eliminado exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      throw Exception('Error al eliminar el platillo');
                    }
                  } else {
                    throw Exception('ID de platillo no encontrado');
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  // Mostrar formulario para editar un platillo existente
  void _mostrarFormularioEditarPlatillo(
    BuildContext context,
    Map<String, dynamic> platillo,
  ) {
    const Color _modalPrimary = Color.fromRGBO(0, 20, 34, 1);
    final TextEditingController nombreController = TextEditingController(
      text: platillo['Platillo']?.toString() ?? '',
    );
    final TextEditingController precioController = TextEditingController(
      text: platillo['Precio']?.toString() ?? '',
    );
    final TextEditingController descripcionController = TextEditingController(
      text: platillo['Descripcion']?.toString() ?? '',
    );
    final TextEditingController imagenController = TextEditingController(
      text: platillo['Imagen']?.toString() ?? '',
    );

    // Convertir a int de forma segura
    int? selectedCategoriaId;
    if (platillo['ID_Categoria'] != null) {
      if (platillo['ID_Categoria'] is int) {
        selectedCategoriaId = platillo['ID_Categoria'];
      } else {
        selectedCategoriaId = int.tryParse(platillo['ID_Categoria'].toString());
      }
    }
    // Si no hay categoría válida, usar la primera disponible
    if (selectedCategoriaId == null && _categorias.isNotEmpty) {
      selectedCategoriaId = _categorias[0]['ID_Categoria'] as int?;
    }

    int selectedEstadoId = 2; // Por defecto Disponible
    if (platillo['ID_Estado'] != null) {
      if (platillo['ID_Estado'] is int) {
        selectedEstadoId = platillo['ID_Estado'];
      } else {
        selectedEstadoId = int.tryParse(platillo['ID_Estado'].toString()) ?? 2;
      }
    }

    Uint8List? imagenBytes;
    String? imagenFilename;
    final ImagePicker _picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
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
                          'Editar Platillo',
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
                                    setModalState(() {});
                                  }
                                },
                                icon: const Icon(Icons.photo_library),
                                label: const Text('Seleccionar imagen'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _modalPrimary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
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
                            setModalState(() {});
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
                              child: Image.memory(
                                imagenBytes!,
                                fit: BoxFit.cover,
                              ),
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
                        // Selector de Categoría
                        if (_categorias.isNotEmpty)
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
                                items: _categorias.map((categoria) {
                                  return DropdownMenuItem<int>(
                                    value: categoria['ID_Categoria'],
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.category,
                                          color: _modalPrimary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          categoria['Descripcion'] ?? '',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setModalState(() {
                                    selectedCategoriaId = value;
                                  });
                                },
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        // Selector de Estado
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
                              items: [
                                DropdownMenuItem<int>(
                                  value: 2,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Disponible',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem<int>(
                                  value: 1,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.cancel,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'No Disponible',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setModalState(() {
                                  selectedEstadoId = value ?? 2;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              // Validaciones
                              if (nombreController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'El nombre del platillo es requerido',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              if (precioController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('El precio es requerido'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              bool success = false;
                              
                              // Asegurar que los IDs sean del tipo correcto
                              dynamic idMenu = platillo['ID_Menu'];
                              if (idMenu is String) {
                                idMenu = int.tryParse(idMenu) ?? idMenu;
                              }
                              
                              dynamic idCategoria = selectedCategoriaId;
                              if (idCategoria is String) {
                                idCategoria = int.tryParse(idCategoria) ?? idCategoria;
                              }
                              
                              dynamic idEstado = selectedEstadoId;
                              if (idEstado is String) {
                                idEstado = int.tryParse(idEstado) ?? idEstado;
                              }
                              
                              final Map<String, dynamic> datosActualizados = {
                                'ID_Menu': idMenu,
                                'Platillo': nombreController.text.trim(),
                                'Precio': precioController.text.trim(),
                                'Descripcion':
                                    descripcionController.text.trim(),
                                'ID_Categoria': idCategoria ?? 1,
                                'ID_Estado': idEstado,
                              };

                              // Solo agregar Imagen si hay una URL nueva
                              if (imagenController.text.trim().isNotEmpty &&
                                  imagenController.text.trim() !=
                                      platillo['Imagen']) {
                                datosActualizados['Imagen'] =
                                    imagenController.text.trim();
                              }

                              print('📤 Datos a actualizar: $datosActualizados');

                              if (imagenBytes != null) {
                                success =
                                    await MenuService.updateMenuItemWithImage(
                                  datosActualizados,
                                  imageBytes: imagenBytes,
                                  imageFilename: imagenFilename ?? 'imagen.jpg',
                                );
                              } else {
                                success = await MenuService.updateMenuItem(
                                  datosActualizados,
                                );
                              }

                              if (success) {
                                Navigator.of(context).pop();
                                _fetchPlatillos();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Platillo actualizado exitosamente',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                // No cerrar el modal para ver el error
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'El servidor rechazó la actualización. Revisa los logs.',
                                    ),
                                    backgroundColor: Colors.orange,
                                    duration: Duration(seconds: 5),
                                  ),
                                );
                              }
                            } catch (e) {
                              print('❌ Exception completa: $e');
                              print('❌ StackTrace: ${StackTrace.current}');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 5),
                                ),
                              );
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

  void _mostrarFormularioPlatilloAdmin(BuildContext context) {
    // Copiado/adaptado del modal de empleado (bottom-sheet con selector de imagen)
    const Color _modalPrimary = Color.fromRGBO(0, 20, 34, 1);
    final TextEditingController nombreController = TextEditingController();
    final TextEditingController precioController = TextEditingController();
    final TextEditingController descripcionController = TextEditingController();
    final TextEditingController imagenController = TextEditingController();

    // Obtener la primera categoría de forma segura
    int? selectedCategoriaId;
    if (_categorias.isNotEmpty) {
      final firstCategoria = _categorias[0]['ID_Categoria'];
      if (firstCategoria is int) {
        selectedCategoriaId = firstCategoria;
      } else if (firstCategoria != null) {
        selectedCategoriaId = int.tryParse(firstCategoria.toString()) ?? 1;
      }
    }
    selectedCategoriaId ??= 1; // Fallback a 1 si no hay categorías

    int selectedEstadoId = 2; // Por defecto Disponible

    Uint8List? imagenBytes;
    String? imagenFilename;
    final ImagePicker _picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
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
                                    setModalState(() {});
                                  }
                                },
                                icon: const Icon(Icons.photo_library),
                                label: const Text('Seleccionar imagen'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _modalPrimary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
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
                            setModalState(() {});
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
                              child: Image.memory(
                                imagenBytes!,
                                fit: BoxFit.cover,
                              ),
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
                        // Selector de Categoría
                        if (_categorias.isNotEmpty)
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
                                items: _categorias.map((categoria) {
                                  return DropdownMenuItem<int>(
                                    value: categoria['ID_Categoria'],
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.category,
                                          color: _modalPrimary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          categoria['Descripcion'] ?? '',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setModalState(() {
                                    selectedCategoriaId = value;
                                  });
                                },
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        // Selector de Estado
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
                              items: [
                                DropdownMenuItem<int>(
                                  value: 2,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Disponible',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem<int>(
                                  value: 1,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.cancel,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'No Disponible',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setModalState(() {
                                  selectedEstadoId = value ?? 2;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              // Validaciones
                              if (nombreController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'El nombre del platillo es requerido',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              if (precioController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('El precio es requerido'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              bool success = false;
                              if (imagenBytes != null) {
                                success =
                                    await MenuService.addMenuItemWithImage(
                                      {
                                        'Platillo': nombreController.text
                                            .trim(),
                                        'Precio': precioController.text.trim(),
                                        'Descripcion': descripcionController
                                            .text
                                            .trim(),
                                        'ID_Categoria':
                                            selectedCategoriaId ?? 1,
                                        'ID_Estado': selectedEstadoId,
                                      },
                                      imageBytes: imagenBytes,
                                      imageFilename:
                                          imagenFilename ?? 'imagen.jpg',
                                    );
                              } else {
                                success = await MenuService.addMenuItem({
                                  'Platillo': nombreController.text.trim(),
                                  'Precio': precioController.text.trim(),
                                  'Descripcion': descripcionController.text
                                      .trim(),
                                  'Imagen': imagenController.text.trim(),
                                  'ID_Categoria': selectedCategoriaId ?? 1,
                                  'ID_Estado': selectedEstadoId,
                                });
                              }
                              if (success) {
                                Navigator.of(context).pop();
                                await _fetchPlatillos();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Platillo agregado exitosamente',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                throw Exception('Error al guardar el platillo');
                              }
                            } catch (e) {
                              print('Error: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
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
}
