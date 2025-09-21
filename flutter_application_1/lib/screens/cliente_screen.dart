import 'package:flutter/material.dart';

class ClienteScreen extends StatefulWidget {
  const ClienteScreen({super.key});

  @override
  State<ClienteScreen> createState() => _ClienteScreenState();
}

class _ClienteScreenState extends State<ClienteScreen> {
  int _selectedIndex = 0;
  String _selectedCategory = 'Todos';
  List<Map<String, dynamic>> _cartItems = [];
  int _cartCount = 0;

  // Categorías de productos
  final List<String> _categories = [
    'Todos',
    'Entradas',
    'Platos Fuertes',
    'Bebidas',
    'Postres',
  ];

  // Mock data para productos del menú
  final List<Map<String, dynamic>> _menuItems = [
    {
      'id': 1,
      'name': 'Ensalada César',
      'description': 'Lechuga, pollo, crutones, queso parmesano',
      'price': 45.00,
      'category': 'Entradas',
      'image': 'assets/LogoPinequitas.png',
      'available': true,
    },
    {
      'id': 2,
      'name': 'Hamburguesa Clásica',
      'description': 'Carne, queso, lechuga, tomate, papas fritas',
      'price': 85.00,
      'category': 'Platos Fuertes',
      'image': 'assets/LogoPinequitas.png',
      'available': true,
    },
    {
      'id': 3,
      'name': 'Coca Cola',
      'description': 'Refresco de cola 355ml',
      'price': 25.00,
      'category': 'Bebidas',
      'image': 'assets/LogoPinequitas.png',
      'available': true,
    },
    {
      'id': 4,
      'name': 'Tiramisú',
      'description': 'Postre italiano con café y mascarpone',
      'price': 55.00,
      'category': 'Postres',
      'image': 'assets/LogoPinequitas.png',
      'available': true,
    },
    {
      'id': 5,
      'name': 'Sopa de Tortilla',
      'description': 'Sopa tradicional con tortilla frita y aguacate',
      'price': 38.00,
      'category': 'Entradas',
      'image': 'assets/LogoPinequitas.png',
      'available': true,
    },
    {
      'id': 6,
      'name': 'Tacos al Pastor',
      'description': 'Orden de 4 tacos con piña y salsa',
      'price': 75.00,
      'category': 'Platos Fuertes',
      'image': 'assets/LogoPinequitas.png',
      'available': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Paleta de colores
    const Color colorPrimario = Color.fromRGBO(0, 20, 34, 1);
    const Color colorFondo = Color.fromARGB(255, 248, 250, 252);
    const Color colorNaranja = Color.fromARGB(255, 255, 152, 0);
    const Color colorVerde = Color.fromARGB(255, 76, 175, 80);
    const Color colorRojo = Color.fromARGB(255, 244, 67, 54);

    return Scaffold(
      backgroundColor: colorFondo,
      appBar: AppBar(
        backgroundColor: colorPrimario,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            // Logo circular con borde elegante
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
                child: Image.asset(
                  'assets/LogoPinequitas.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Menú', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        elevation: 0,
        actions: [
          // Carrito de compras
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedIndex = 2; // Ir al carrito
                  });
                },
                icon: const Icon(Icons.shopping_cart),
              ),
              if (_cartCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorRojo,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_cartCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
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
          _buildMenuView(colorPrimario, colorNaranja, colorVerde),
          _buildCartView(colorPrimario, colorNaranja, colorVerde),
          _buildOrderStatusView(colorPrimario, colorVerde, colorNaranja),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: colorPrimario,
        unselectedItemColor: Colors.grey[600],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Menú',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart),
                if (_cartCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: colorRojo,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '$_cartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Carrito',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Mis Pedidos',
          ),
        ],
      ),
    );
  }

  // ✅ VISTA DEL MENÚ CON FILTROS
  Widget _buildMenuView(
    Color colorPrimario,
    Color colorNaranja,
    Color colorVerde,
  ) {
    // Filtrar productos por categoría
    List<Map<String, dynamic>> filteredItems = _selectedCategory == 'Todos'
        ? _menuItems
        : _menuItems
              .where((item) => item['category'] == _selectedCategory)
              .toList();

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
                  '¡Bienvenido!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Descubre nuestro delicioso menú',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Filtros de categorías
          Text(
            'Categorías',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorPrimario,
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;

                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? colorPrimario : Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: isSelected ? colorPrimario : Colors.grey[300]!,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Lista de productos
          Text(
            'Productos (${filteredItems.length})',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorPrimario,
            ),
          ),
          const SizedBox(height: 16),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              return _buildMenuItemCard(
                item,
                colorPrimario,
                colorNaranja,
                colorVerde,
              );
            },
          ),
        ],
      ),
    );
  }

  // ✅ VISTA DEL CARRITO
  Widget _buildCartView(
    Color colorPrimario,
    Color colorNaranja,
    Color colorVerde,
  ) {
    double total = _cartItems.fold(
      0.0,
      (sum, item) => sum + (item['price'] * item['quantity']),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado del carrito
          Text(
            'Mi Carrito',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorPrimario,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_cartItems.length} productos agregados',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),

          const SizedBox(height: 20),

          // Lista de productos en el carrito
          if (_cartItems.isEmpty)
            _buildEmptyCart(colorPrimario)
          else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                final item = _cartItems[index];
                return _buildCartItemCard(item, colorPrimario, index);
              },
            ),

            const SizedBox(height: 24),

            // Resumen del pedido
            Container(
              padding: const EdgeInsets.all(20),
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
                  Text(
                    'Resumen del Pedido',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorPrimario,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subtotal:'),
                      Text('\$${total.toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text('Envío:'), Text('\$15.00')],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorPrimario,
                        ),
                      ),
                      Text(
                        '\$${(total + 15).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorNaranja,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Botón de realizar pedido
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Realizar pedido
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorVerde,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Realizar Pedido',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ✅ VISTA DEL ESTADO DE PEDIDOS
  Widget _buildOrderStatusView(
    Color colorPrimario,
    Color colorVerde,
    Color colorNaranja,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Text(
            'Mis Pedidos',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorPrimario,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Historial y estado de tus pedidos',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),

          const SizedBox(height: 20),

          // Lista de pedidos (mock data)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) {
              return _buildOrderStatusCard(
                'Pedido #${5000 + index}',
                _getOrderStatus(index),
                '${DateTime.now().subtract(Duration(hours: index + 1)).day}/${DateTime.now().month}',
                '\$${(index + 1) * 45}.00',
                colorPrimario,
                colorVerde,
                colorNaranja,
                index,
              );
            },
          ),
        ],
      ),
    );
  }

  // ✅ WIDGETS AUXILIARES
  Widget _buildMenuItemCard(
    Map<String, dynamic> item,
    Color colorPrimario,
    Color colorNaranja,
    Color colorVerde,
  ) {
    return Container(
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
          // Imagen del producto
          Expanded(
            flex: 3,
            child: Container(
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
                child: Image.asset(
                  item['image'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.restaurant,
                      size: 40,
                      color: Colors.grey[400],
                    );
                  },
                ),
              ),
            ),
          ),

          // Información del producto
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorPrimario,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['description'],
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${item['price'].toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorNaranja,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _addToCart(item);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colorVerde,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 16,
                          ),
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
    );
  }

  Widget _buildCartItemCard(
    Map<String, dynamic> item,
    Color colorPrimario,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
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
          // Imagen del producto
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                item['image'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.restaurant, color: Colors.grey[400]);
                },
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Información del producto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorPrimario,
                  ),
                ),
                Text(
                  '\$${item['price'].toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Controles de cantidad
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  _decreaseQuantity(index);
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.remove, size: 16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${item['quantity']}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  _increaseQuantity(index);
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorPrimario,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(Color colorPrimario) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Tu carrito está vacío',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorPrimario,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega productos del menú para comenzar',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedIndex = 0;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorPrimario,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Explorar Menú'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusCard(
    String orderNumber,
    String status,
    String date,
    String total,
    Color colorPrimario,
    Color colorVerde,
    Color colorNaranja,
    int index,
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorPrimario,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getOrderStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    color: _getOrderStatusColor(status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Fecha: $date'),
          Text('Total: $total'),
          const SizedBox(height: 12),

          // Progreso del pedido
          _buildOrderProgress(status, colorPrimario, colorVerde, colorNaranja),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Ver detalles del pedido
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorPrimario,
                    side: BorderSide(color: colorPrimario),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Ver Detalles'),
                ),
              ),
              if (status == 'Preparando') ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Rastrear pedido
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorNaranja,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Rastrear'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderProgress(
    String status,
    Color colorPrimario,
    Color colorVerde,
    Color colorNaranja,
  ) {
    final steps = ['Confirmado', 'Preparando', 'En Camino', 'Entregado'];
    final currentStep = steps.indexOf(status);

    return Row(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final isCompleted = index <= currentStep;

        return Expanded(
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isCompleted ? colorVerde : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 12)
                    : null,
              ),
              if (index < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted ? colorVerde : Colors.grey[300],
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ✅ FUNCIONES AUXILIARES
  void _addToCart(Map<String, dynamic> item) {
    setState(() {
      final existingIndex = _cartItems.indexWhere(
        (cartItem) => cartItem['id'] == item['id'],
      );

      if (existingIndex >= 0) {
        _cartItems[existingIndex]['quantity']++;
      } else {
        _cartItems.add({...item, 'quantity': 1});
      }

      _cartCount = _cartItems.fold(
        0,
        (sum, item) => sum + (item['quantity'] as int),
      );
    });
  }

  void _increaseQuantity(int index) {
    setState(() {
      _cartItems[index]['quantity']++;
      _cartCount = _cartItems.fold(
        0,
        (sum, item) => sum + (item['quantity'] as int),
      );
    });
  }

  void _decreaseQuantity(int index) {
    setState(() {
      if (_cartItems[index]['quantity'] > 1) {
        _cartItems[index]['quantity']--;
      } else {
        _cartItems.removeAt(index);
      }
      _cartCount = _cartItems.fold(
        0,
        (sum, item) => sum + (item['quantity'] as int),
      );
    });
  }

  String _getOrderStatus(int index) {
    final statuses = ['Confirmado', 'Preparando', 'En Camino', 'Entregado'];
    return statuses[index % statuses.length];
  }

  Color _getOrderStatusColor(String status) {
    switch (status) {
      case 'Confirmado':
        return Colors.blue;
      case 'Preparando':
        return Colors.orange;
      case 'En Camino':
        return Colors.purple;
      case 'Entregado':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
