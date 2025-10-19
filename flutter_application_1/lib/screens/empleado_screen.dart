import 'package:flutter/material.dart';
import '../services/menu_service.dart';
import '../widgets/flexible_image.dart';

class EmpleadoScreen extends StatefulWidget {
  const EmpleadoScreen({super.key});

  @override
  State<EmpleadoScreen> createState() => _EmpleadoScreenState();
}

class _EmpleadoScreenState extends State<EmpleadoScreen> {
  int _selectedIndex = 0;
  List<dynamic> _menuItems = [];

  @override
  void initState() {
    super.initState();
    _fetchMenuItems();
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

  void _mostrarFormularioPlatilloEmpleado(BuildContext context) {
    // Usar el color primario de la app para los modales
    const Color _modalPrimary = Color.fromRGBO(0, 20, 34, 1);
    final TextEditingController nombreController = TextEditingController();
    final TextEditingController precioController = TextEditingController();
    final TextEditingController descripcionController = TextEditingController();
    int? categoriaSeleccionada;
    int? estadoSeleccionado;

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
                    DropdownButtonFormField<int>(
                      value: categoriaSeleccionada,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        hintText: 'Seleccionar Categoría',
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
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Entradas')),
                        DropdownMenuItem(
                          value: 2,
                          child: Text('Platos Fuertes'),
                        ),
                        DropdownMenuItem(value: 3, child: Text('Postres')),
                        DropdownMenuItem(value: 4, child: Text('Bebidas')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          categoriaSeleccionada = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: estadoSeleccionado,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        hintText: 'Seleccionar Estado',
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
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Disponible')),
                        DropdownMenuItem(
                          value: 2,
                          child: Text('No Disponible'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          estadoSeleccionado = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          final success = await MenuService.addMenuItem({
                            'Platillo': nombreController.text,
                            'Precio': precioController.text,
                            'Descripcion': descripcionController.text,
                            'ID_Categoria': categoriaSeleccionada,
                            'ID_Estado': estadoSeleccionado,
                          });
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
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
        // Al tocar, mostrar el formulario de edición (reusar el diálogo de agregar)
        _mostrarFormularioPlatilloEmpleado(context);
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
                // Imagen con altura fija relativa
                Container(
                  height: imageH,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: FlexibleImage(
                      source: item['Imagen'] ?? item['image'],
                      name: item['Platillo'] ?? item['name'],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Información (nombre + precio) con altura limitada
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
      ),//hola
    );//drgdrgdrsefsef
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
