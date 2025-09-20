import 'package:flutter/material.dart';

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
  final List<Map<String, dynamic>> _platillos = [
    {
      'nombre': 'Hamburguesa Clásica',
      'precio': 12.99,
      'imagen': 'assets/Logo.png', // Placeholder image
    },
    {
      'nombre': 'Pizza Margherita',
      'precio': 18.50,
      'imagen': 'assets/Logo.png', // Placeholder image
    },
    {
      'nombre': 'Ensalada César',
      'precio': 9.75,
      'imagen': 'assets/Logo.png', // Placeholder image
    },
  ];

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
              child: ListView.builder(
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
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: colorPrimario.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              // Imagen del platillo
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey.shade200,
                                  border: Border.all(
                                    color: colorPrimario.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: platillo['imagen'] != null
                                      ? Image.asset(
                                          platillo['imagen'],
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey.shade300,
                                                  child: Icon(
                                                    Icons.restaurant,
                                                    color: colorPrimario,
                                                    size: 40,
                                                  ),
                                                );
                                              },
                                        )
                                      : Container(
                                          color: Colors.grey.shade300,
                                          child: Icon(
                                            Icons.restaurant,
                                            color: colorPrimario,
                                            size: 40,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Información del platillo
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Nombre del platillo
                                    Text(
                                      platillo['nombre'] ?? '',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: colorTexto,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // Precio
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.attach_money,
                                          size: 16,
                                          color: Colors.green.shade600,
                                        ),
                                        Text(
                                          '\$${platillo['precio']?.toStringAsFixed(2) ?? '0.00'}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Botones de acción
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            // TODO: Implementar edición de platillo
                                          },
                                          icon: Icon(
                                            Icons.edit,
                                            size: 16,
                                            color: colorPrimario,
                                          ),
                                          label: Text(
                                            'Editar',
                                            style: TextStyle(
                                              color: colorPrimario,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                              color: colorPrimario,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            // TODO: Implementar eliminación de platillo
                                          },
                                          icon: const Icon(
                                            Icons.delete,
                                            size: 16,
                                            color: Colors.red,
                                          ),
                                          label: const Text(
                                            'Eliminar',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                              color: Colors.red,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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

  // Modal para agregar/editar platillo
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
                    style: TextStyle(color: colorTexto),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      hintText: 'Nombre del platillo',
                      hintStyle: TextStyle(color: colorTexto.withOpacity(0.6)),
                      prefixIcon: Icon(
                        Icons.restaurant_menu,
                        color: colorPrimario,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorPrimario, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorPrimario, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Campo Precio
                  TextField(
                    controller: precioController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: TextStyle(color: colorTexto),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      hintText: 'Precio (ej: 12.99)',
                      hintStyle: TextStyle(color: colorTexto.withOpacity(0.6)),
                      prefixIcon: Icon(
                        Icons.attach_money,
                        color: Colors.green.shade600,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorPrimario, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorPrimario, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sección de imagen
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorPrimario.withOpacity(0.3),
                        width: 1,
                      ),
                      color: Colors.grey.shade50,
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.image, size: 48, color: colorPrimario),
                        const SizedBox(height: 8),
                        Text(
                          'Imagen del Platillo',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colorTexto,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Selecciona una imagen para el platillo',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorTexto.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Implementar selección de imagen
                          },
                          icon: Icon(Icons.upload, color: colorPrimario),
                          label: Text(
                            'Seleccionar Imagen',
                            style: TextStyle(color: colorPrimario),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colorPrimario),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

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
                                    'nombre': nombreController.text,
                                    'precio': precio,
                                    'imagen':
                                        'assets/Logo.png', // Placeholder por ahora
                                  });
                                });
                                Navigator.of(context).pop();

                                // TODO: Aquí implementar lógica para guardar en base de datos
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
