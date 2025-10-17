import 'package:flutter/material.dart';
import '../services/menu_service.dart';

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
                  _mostrarFormularioPlatillo(context);
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
                                    'Estado: ${platillo['ID_Estado'] == 2 ? 'Disponible' : 'No disponible'}',
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

  void _mostrarFormularioPlatillo(BuildContext context) {
    final TextEditingController nombreController = TextEditingController();
    final TextEditingController precioController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Agregar Nuevo Platillo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorPrimario,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Campo Nombre del Platillo
                  TextField(
                    controller: nombreController,
                    decoration: InputDecoration(
                      labelText: 'Nombre del Platillo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Campo Precio del Platillo
                  TextField(
                    controller: precioController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Precio',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorPrimario,
                            side: BorderSide(color: colorPrimario),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (nombreController.text.isNotEmpty &&
                                precioController.text.isNotEmpty) {
                              // Validar que el precio sea un número válido
                              double? precio = double.tryParse(
                                precioController.text,
                              );
                              if (precio != null) {
                                // Agregar platillo a la lista
                                setState(() {
                                  _platillos.add({
                                    'Platillo': nombreController.text,
                                    'Precio': precio,
                                    'Descripcion': 'Descripción pendiente',
                                    'Imagen': null,
                                  });
                                });
                                Navigator.of(context).pop();
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorPrimario,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Guardar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
