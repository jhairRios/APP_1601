import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/flexible_image.dart';
import '../services/api_config.dart';
import '../services/order_service.dart';
import '../utils/web_open.dart';

class RepartidorScreen extends StatefulWidget {
  const RepartidorScreen({super.key});

  @override
  State<RepartidorScreen> createState() => _RepartidorScreenState();
}

class _RepartidorScreenState extends State<RepartidorScreen> {
  int _selectedIndex = 0;
  // Estados para pedidos
  List<Map<String, dynamic>> _pendingOrders = [];
  List<Map<String, dynamic>> _myOrders = [];
  bool _loadingPending = false;
  bool _loadingMy = false;
  String? _pendingError;
  String? _myError;
  String? _myRawResponse;
  String? _pendingRawResponse;
  String? _currentRepartidorId;
  late StreamSubscription<Map<String, dynamic>> _orderSubscription;
  Timer? _pollTimer;

  @override
  Widget build(BuildContext context) {
    // Paleta de colores
    const Color colorPrimario = Color.fromRGBO(0, 20, 34, 1);
    const Color colorFondo = Color.fromARGB(255, 248, 250, 252);
    const Color colorNaranja = Color.fromARGB(255, 255, 152, 0);
    const Color colorVerde = Color.fromARGB(255, 76, 175, 80);
    const Color colorAzul = Color.fromARGB(255, 33, 150, 243);

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
                child: FlexibleImage(
                  source: 'assets/LogoPinequitas.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Panel Repartidor',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_currentRepartidorId != null)
                  Text(
                    'ID: ${_currentRepartidorId}',
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              // Estado del repartidor (disponible/ocupado)
            },
            icon: const Icon(Icons.location_on),
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
          _buildDashboard(colorPrimario, colorNaranja, colorVerde, colorAzul),
          _buildPedidosPendientes(colorPrimario, colorNaranja),
          _buildMisPedidos(colorPrimario, colorVerde),
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.pending_actions),
            label: 'Pendientes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Mis Pedidos',
          ),
        ],
      ),
    );
  }

  Future<void> _openMapForOrder(String orderId) async {
    // show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final resp = await http.post(
        Uri.parse(API_BASE_URL),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'action': 'get_order_detail', 'order_id': orderId}),
      );
      if (mounted) Navigator.of(context).pop();
      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body);
        if (decoded != null && decoded['success'] == true) {
          final pedido = decoded['pedido'] ?? {};
          final ubicacion = (pedido['Ubicacion'] ?? pedido['ubicacion'] ?? '')
              .toString();
          if (ubicacion.trim().isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No hay ubicación disponible para este pedido'),
                ),
              );
            }
            return;
          }
          final mapsUrl =
              'https://www.google.com/maps/search/?api=1&query=' +
              Uri.encodeComponent(ubicacion);
          try {
            openInNewTab(mapsUrl);
          } catch (_) {
            // If platform doesn't support opening, show the URL for manual copy
            await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Abrir mapa'),
                content: SelectableText(mapsUrl),
                actions: [
                  TextButton(
                    onPressed: () {
                      if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
                    },
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            );
          }
          return;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo obtener el detalle del pedido'),
          ),
        );
      }
    } catch (e) {
      try {
        if (mounted) Navigator.of(context).pop();
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // ✅ DASHBOARD PRINCIPAL
  Widget _buildDashboard(
    Color colorPrimario,
    Color colorNaranja,
    Color colorVerde,
    Color colorAzul,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bienvenida y estado
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¡Hola, Repartidor!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Listo para entregar pedidos',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorVerde,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.white, size: 8),
                          const SizedBox(width: 6),
                          Text(
                            'Disponible',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Estadísticas del día
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Entregas Hoy',
                  '${_myOrders.length}',
                  Icons.delivery_dining,
                  colorVerde,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Pendientes',
                  '${_pendingOrders.length}',
                  Icons.pending,
                  colorNaranja,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Ingresos',
                  '\$125',
                  Icons.monetization_on,
                  colorAzul,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Accesos rápidos
          Text(
            'Acciones Rápidas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorPrimario,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  'Ver Pedidos\nPendientes',
                  Icons.pending_actions,
                  colorNaranja,
                  () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  'Mis Pedidos\nAsignados',
                  Icons.assignment,
                  colorVerde,
                  () {
                    setState(() {
                      _selectedIndex = 2;
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Último pedido entregado
          Text(
            'Última Entrega',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorPrimario,
            ),
          ),
          const SizedBox(height: 12),

          _buildLastDeliveryCard(colorPrimario, colorVerde),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // cargar cache local primero para mostrar algo inmediatamente
    _loadOrderCaches();
    // cargar listas desde servidor
    _loadPendingOrders();
    _loadMyOrders();
    // cargar id de repartidor (si existe)
    _loadRepartidorId();
    // Suscribirse a notificaciones locales de nuevos pedidos (mismo proceso)
    try {
      _orderSubscription = OrderService.orderStream.listen((order) {
        try {
          debugPrint('[repartidor] received order notify -> ${order.toString()}');
          // Forzar recarga para reflejar nuevos pedidos creados por clientes
          _loadPendingOrders();
          _loadMyOrders();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            try {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nuevo pedido recibido')),
              );
            } catch (_) {}
          });
        } catch (e) {
          debugPrint('[repartidor] order subscription handler error: $e');
        }
      });
    } catch (e) {
      debugPrint('[repartidor] order subscription setup failed: $e');
    }

    // Iniciar polling periódico para asegurarnos de recibir pedidos cuando
    // la notificación local no aplique (por ejemplo multi-dispositivo).
    try {
      _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _loadPendingOrders();
      });
    } catch (e) {
      debugPrint('[repartidor] poll timer failed: $e');
    }
  }

  @override
  void dispose() {
    try {
      _orderSubscription.cancel();
    } catch (_) {}
    try {
      _pollTimer?.cancel();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _loadRepartidorId() async {
    final id = await _getRepartidorId();
    setState(() {
      _currentRepartidorId = id;
    });
  }

  // ✅ PEDIDOS PENDIENTES/SIN ASIGNAR
  Widget _buildPedidosPendientes(Color colorPrimario, Color colorNaranja) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pedidos Pendientes',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorPrimario,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorNaranja.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorNaranja.withOpacity(0.3)),
                ),
                child: Text(
                  '${_pendingOrders.length} disponibles',
                  style: TextStyle(
                    color: colorNaranja,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Text(
            'Pedidos listos para ser tomados',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),

          const SizedBox(height: 20),

          // Lista de pedidos pendientes
          if (_loadingPending)
            const Center(child: CircularProgressIndicator())
          else if (_pendingOrders.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_pendingError ?? 'No hay pedidos pendientes'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loadPendingOrders,
                  child: const Text('Refrescar'),
                ),
                if (_pendingRawResponse != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Respuesta servidor (preview):',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _pendingRawResponse!.length > 800
                          ? _pendingRawResponse!.substring(
                                  0,
                                  math.min(800, _pendingRawResponse!.length),
                                ) +
                                '...'
                          : _pendingRawResponse!,
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ],
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pendingOrders.length,
              itemBuilder: (context, index) {
                final o = _pendingOrders[index];
                final orderId =
                    o['ID_Pedidos'] ??
                    o['ID_Pedido'] ??
                    o['Id_Pedido'] ??
                    o['id'] ??
                    o['order_id'] ??
                    o['orderId'] ??
                    o['ID'] ??
                    '';
                final restaurant =
                    o['Restaurante'] ??
                    o['restaurante'] ??
                    o['nombre_restaurante'] ??
                    'Restaurante';
                final address =
                    o['Ubicacion'] ??
                    o['ubicacion'] ??
                    o['Direccion'] ??
                    o['direccion'] ??
                    '';
                final distance = o['distancia'] ?? '';
                final payment =
                    o['Total'] ?? o['total'] ?? o['monto'] ?? '\$0.00';
                return _buildPendingOrderCard(
                  'Pedido #${orderId}',
                  restaurant.toString(),
                  address.toString(),
                  distance.toString(),
                  payment.toString(),
                  colorPrimario,
                  colorNaranja,
                  index,
                  orderId: orderId.toString(),
                );
              },
            ),
        ],
      ),
    );
  }

  // ✅ MIS PEDIDOS ASIGNADOS
  Widget _buildMisPedidos(Color colorPrimario, Color colorVerde) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mis Pedidos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorPrimario,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorVerde.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorVerde.withOpacity(0.3)),
                ),
                child: Text(
                  '${_myOrders.length} asignados',
                  style: TextStyle(
                    color: colorVerde,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Text(
            'Pedidos que tienes asignados',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),

          const SizedBox(height: 20),

          // Lista de mis pedidos
          if (_loadingMy)
            const Center(child: CircularProgressIndicator())
          else if (_myOrders.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_myError ?? 'No tienes pedidos asignados'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loadMyOrders,
                  child: const Text('Refrescar'),
                ),
                if (_myRawResponse != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Respuesta servidor (preview):',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _myRawResponse!.length > 800
                          ? _myRawResponse!.substring(
                                  0,
                                  math.min(800, _myRawResponse!.length),
                                ) +
                                '...'
                          : _myRawResponse!,
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ],
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _myOrders.length,
              itemBuilder: (context, index) {
                final o = _myOrders[index];
                final orderId =
                    o['ID_Pedidos'] ??
                    o['ID_Pedido'] ??
                    o['Id_Pedido'] ??
                    o['id'] ??
                    o['order_id'] ??
                    o['orderId'] ??
                    o['ID'] ??
                    '';
                final cliente =
                    o['Cliente'] ?? o['cliente'] ?? o['Nombre'] ?? 'Cliente';
                final address =
                    o['Ubicacion'] ??
                    o['ubicacion'] ??
                    o['Direccion'] ??
                    o['direccion'] ??
                    '';
                final status =
                    o['Estado'] ?? o['estado'] ?? o['status'] ?? 'Asignado';
                final distance = o['distancia'] ?? '';
                final payment =
                    o['Total'] ?? o['total'] ?? o['monto'] ?? '\$0.00';
                return _buildMyOrderCard(
                  'Pedido #${orderId}',
                  cliente.toString(),
                  address.toString(),
                  status.toString(),
                  distance.toString(),
                  payment.toString(),
                  colorPrimario,
                  colorVerde,
                  index,
                  orderId: orderId.toString(),
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
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
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

  Widget _buildLastDeliveryCard(Color colorPrimario, Color colorVerde) {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorVerde.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.check_circle, color: colorVerde, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pedido #2587',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorPrimario,
                  ),
                ),
                Text(
                  'Cliente: María González',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  'Entregado hace 30 min',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '\$25.00',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorVerde,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingOrderCard(
    String orderNumber,
    String restaurant,
    String address,
    String distance,
    String payment,
    Color colorPrimario,
    Color colorNaranja,
    int index, {
    String? orderId,
  }) {
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
                  color: colorNaranja.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Pendiente',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorNaranja,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Restaurante: $restaurant'),
          Text('Dirección: $address'),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              Text(' $distance'),
              const SizedBox(width: 16),
              Icon(Icons.monetization_on, size: 16, color: Colors.grey[600]),
              Text(' $payment'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: orderId == null
                  ? null
                  : () async {
                      await _assignOrder(orderId);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorNaranja,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Tomar Pedido'),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------ Llamadas a API y helpers ------------------
  Future<String?> _getRepartidorId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('repartidor_id') ?? prefs.getString('user_id');
      return id;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadPendingOrders() async {
    setState(() {
      _loadingPending = true;
      _pendingError = null;
      _pendingRawResponse = null;
    });
    try {
      debugPrint('[repartidor] _loadPendingOrders: request -> ${API_BASE_URL}');
      final resp = await http.post(
        Uri.parse(API_BASE_URL),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'action': 'get_pending_orders'}),
      );
      debugPrint('[repartidor] _loadPendingOrders: status=${resp.statusCode}');
      debugPrint('[repartidor] _loadPendingOrders: body=${resp.body}');
      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body);
        List<dynamic> ordersRaw = [];
        if (decoded is List) {
          ordersRaw = decoded;
        } else if (decoded is Map) {
          if (decoded['orders'] != null)
            ordersRaw = decoded['orders'];
          else if (decoded['data'] != null)
            ordersRaw = decoded['data'];
          else if (decoded['pedidos'] != null)
            ordersRaw = decoded['pedidos'];
          else if (decoded['success'] == true && decoded.length == 1) {
            // Caso raro donde el servidor devuelve {"success":true} sin orders
            ordersRaw = [];
          }
        }

        if (ordersRaw.isNotEmpty) {
          setState(() {
            _pendingOrders = List<Map<String, dynamic>>.from(
              ordersRaw.map(
                (e) => e is Map ? Map<String, dynamic>.from(e) : {'value': e},
              ),
            );
          });
        } else {
          setState(() {
            _pendingOrders = [];
            _pendingRawResponse = resp.body;
            _pendingError =
                'No hay pedidos pendientes recibidos desde el servidor';
          });
        }
      } else {
        setState(() {
          _pendingError = 'HTTP ${resp.statusCode}';
          _pendingRawResponse = resp.body;
        });
      }
    } catch (e) {
      setState(() {
        _pendingError = 'Error: $e';
        _pendingRawResponse = e.toString();
      });
    } finally {
      setState(() {
        _loadingPending = false;
      });
    }
  }

  // Persistir/recuperar cache local de pedidos para mantener UI consistente
  Future<void> _saveOrderCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_orders_cache', json.encode(_pendingOrders));
      await prefs.setString('my_orders_cache', json.encode(_myOrders));
    } catch (e) {
      debugPrint('[repartidor] _saveOrderCaches failed: $e');
    }
  }

  Future<void> _loadOrderCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final p = prefs.getString('pending_orders_cache');
      final m = prefs.getString('my_orders_cache');
      if (p != null && p.isNotEmpty) {
        final parsed = json.decode(p);
        if (parsed is List) {
          setState(() {
            _pendingOrders = List<Map<String, dynamic>>.from(parsed.map((e) => e is Map ? Map<String, dynamic>.from(e) : {'value': e}));
          });
        }
      }
      if (m != null && m.isNotEmpty) {
        final parsed = json.decode(m);
        if (parsed is List) {
          setState(() {
            _myOrders = List<Map<String, dynamic>>.from(parsed.map((e) => e is Map ? Map<String, dynamic>.from(e) : {'value': e}));
          });
        }
      }
    } catch (e) {
      debugPrint('[repartidor] _loadOrderCaches failed: $e');
    }
  }

  Future<void> _loadMyOrders() async {
    setState(() {
      _loadingMy = true;
      _myError = null;
      _myRawResponse = null;
    });
    try {
      debugPrint('[repartidor] _loadMyOrders: starting');
      final id = await _getRepartidorId();
      if (id == null) {
        setState(() {
          _myError = 'No hay repartidor_id en sesión';
          _myOrders = [];
        });
        return;
      }
      final resp = await http.post(
        Uri.parse(API_BASE_URL),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'get_repartidor_orders',
          'repartidor_id': id,
        }),
      );
      debugPrint('[repartidor] _loadMyOrders: status=${resp.statusCode}');
      debugPrint('[repartidor] _loadMyOrders: body=${resp.body}');
      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body);
        if (decoded is Map &&
            decoded['success'] == true &&
            decoded['orders'] != null) {
          setState(() {
            _myOrders = List<Map<String, dynamic>>.from(decoded['orders']);
          });
        } else {
          // intentar aceptar otras formas (data/pedidos) o guardar raw para debug
          List<dynamic> ordersRaw = [];
          if (decoded is List)
            ordersRaw = decoded;
          else if (decoded is Map) {
            if (decoded['orders'] != null)
              ordersRaw = decoded['orders'];
            else if (decoded['data'] != null)
              ordersRaw = decoded['data'];
            else if (decoded['pedidos'] != null)
              ordersRaw = decoded['pedidos'];
          }
          if (ordersRaw.isNotEmpty) {
            setState(() {
              _myOrders = List<Map<String, dynamic>>.from(
                ordersRaw.map(
                  (e) => e is Map ? Map<String, dynamic>.from(e) : {'value': e},
                ),
              );
            });
          } else {
            setState(() {
              _myError = 'Respuesta inválida del servidor';
              _myRawResponse = resp.body;
            });
          }
        }
      } else {
        setState(() {
          _myError = 'HTTP ${resp.statusCode}';
          _myRawResponse = resp.body;
        });
      }
    } catch (e) {
      setState(() {
        _myError = 'Error: $e';
      });
    } finally {
      setState(() {
        _loadingMy = false;
      });
    }
  }

  Future<void> _assignOrder(String orderId) async {
    final id = await _getRepartidorId();
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay repartidor en sesión')),
      );
      return;
    }
    try {
      // sanitize order id to digits only (defensive: some sources may include '#')
      final sanitizedOrderId = orderId.toString().replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      debugPrint(
        '[repartidor] assign_order payload: order_id=$sanitizedOrderId repartidor_id=$id',
      );
      final resp = await http.post(
        Uri.parse(API_BASE_URL),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'assign_order',
          'order_id': sanitizedOrderId,
          'repartidor_id': id,
        }),
      );
      debugPrint(
        '[repartidor] assign_order response: status=${resp.statusCode} body=${resp.body}',
      );
      final decoded = resp.statusCode == 200 ? json.decode(resp.body) : null;
      if (decoded != null && decoded['success'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pedido asignado')));
        // Si el servidor devuelve la fila actualizada, sincronizamos cache y listas inmediatamente
        final updated = decoded['order'];
        if (updated != null && updated is Map) {
          final up = Map<String, dynamic>.from(updated);
          final oid = (up['ID_Pedido'] ?? up['id'] ?? up['ID'] ?? up['order_id'] ?? '').toString();
          setState(() {
            // remover de pendientes
            _pendingOrders.removeWhere((o) {
              final existingId = (o['ID_Pedido'] ?? o['id'] ?? o['ID'] ?? o['order_id'] ?? '').toString();
              return existingId == oid;
            });
            // agregar a mis pedidos si no existe
            final exists = _myOrders.any((o) {
              final existingId = (o['ID_Pedido'] ?? o['id'] ?? o['ID'] ?? o['order_id'] ?? '').toString();
              return existingId == oid;
            });
            if (!exists) {
              _myOrders.insert(0, up);
            } else {
              // actualizar si ya existía
              for (int i = 0; i < _myOrders.length; i++) {
                final existingId = (_myOrders[i]['ID_Pedido'] ?? _myOrders[i]['id'] ?? _myOrders[i]['ID'] ?? _myOrders[i]['order_id'] ?? '').toString();
                if (existingId == oid) { _myOrders[i] = up; break; }
              }
            }
          });
          try { await _saveOrderCaches(); } catch (_) {}
          // notificar a otros listeners locales (empleado/cliente en mismo dispositivo)
          try { OrderService.notifyNewOrder(up); } catch (_) {}
        } else {
          await _loadPendingOrders();
          await _loadMyOrders();
        }
      } else {
        final msg = decoded?['message'] ?? 'Error asignando';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$msg')));
        // keep the full body in debug logs for troubleshooting
        debugPrint(
          '[repartidor] assign_order decoded=$decoded raw=${resp.body}',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error de red: $e')));
    }
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      final sanitizedOrderId = orderId.toString().replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      debugPrint(
        '[repartidor] update_order_status payload: order_id=$sanitizedOrderId status=$status',
      );
      final resp = await http.post(
        Uri.parse(API_BASE_URL),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'update_order_status',
          'order_id': sanitizedOrderId,
          'status': status,
        }),
      );
      debugPrint(
        '[repartidor] update_order_status response: status=${resp.statusCode} body=${resp.body}',
      );
      final decoded = resp.statusCode == 200 ? json.decode(resp.body) : null;
      if (decoded != null && decoded['success'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Estado actualizado: $status')));
        // actualizar la fila localmente si el servidor la devolvió
        final updated = decoded['order'];
        if (updated != null && updated is Map) {
          final up = Map<String, dynamic>.from(updated);
          final oid = (up['ID_Pedido'] ?? up['id'] ?? up['ID'] ?? up['order_id'] ?? '').toString();
          setState(() {
            // intentar actualizar en mis pedidos
            var updatedInMy = false;
            for (int i = 0; i < _myOrders.length; i++) {
              final existingId = (_myOrders[i]['ID_Pedido'] ?? _myOrders[i]['id'] ?? _myOrders[i]['ID'] ?? _myOrders[i]['order_id'] ?? '').toString();
              if (existingId == oid) {
                _myOrders[i] = up;
                updatedInMy = true;
                break;
              }
            }
            if (!updatedInMy) {
              // If it's not in myOrders but now assigned to me, insert it
              _myOrders.insert(0, up);
            }
            // Also remove from pending if status moved past available
            if (status == 'En Camino' || status == 'Entregado') {
              _pendingOrders.removeWhere((o) {
                final existingId = (o['ID_Pedido'] ?? o['id'] ?? o['ID'] ?? o['order_id'] ?? '').toString();
                return existingId == oid;
              });
            }
          });
          try { await _saveOrderCaches(); } catch (_) {}
          try { OrderService.notifyNewOrder(up); } catch (_) {}
        } else {
          await _loadMyOrders();
        }
      } else {
        final msg = decoded?['message'] ?? 'Error actualizando';
        // Mostrar el mensaje legible y conservar la respuesta completa en logs
        String display = msg;
        if (decoded != null) {
          final current = decoded['current_status'];
          final currentLabel = decoded['current_status_label'];
          if (currentLabel != null && currentLabel.toString().isNotEmpty) {
            if (currentLabel == status) {
              display = 'El pedido ya está en estado: $currentLabel';
            } else {
              display = '$msg (estado actual: $currentLabel)';
            }
          } else if (current != null) {
            if (current.toString() == status) {
              display = 'El pedido ya está en estado: $current';
            } else {
              display = '$msg (estado actual: $current)';
            }
          }
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(display)));
        debugPrint(
          '[repartidor] update_order_status failed decoded=$decoded raw=${resp.body}',
        );
        // refrescar lista para asegurar que UI muestre el estado real
        await _loadMyOrders();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error de red: $e')));
    }
  }

  Widget _buildMyOrderCard(
    String orderNumber,
    String customer,
    String address,
    String status,
    String distance,
    String payment,
    Color colorPrimario,
    Color colorVerde,
    int index, {
    String? orderId,
  }) {
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
          Text('Dirección: $address'),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              Text(' $distance'),
              const SizedBox(width: 16),
              Icon(Icons.monetization_on, size: 16, color: Colors.grey[600]),
              Text(' $payment'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: orderId == null
                      ? null
                      : () async {
                          await _openMapForOrder(orderId);
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorPrimario,
                    side: BorderSide(color: colorPrimario),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.map, size: 16),
                  label: const Text('Mapa'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (orderId == null || status == 'En Camino' || status == 'Entregado')
                      ? (orderId == null ? null : () async {})
                      : () async {
                          // iniciar recorrido -> poner En Camino
                          await _updateOrderStatus(orderId, 'En Camino');
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorVerde,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.directions_bike, size: 16),
                  label: const Text('Iniciar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (orderId == null || status == 'Entregado')
                      ? (orderId == null ? null : () async {})
                      : () async {
                          // marcar entregado
                          await _updateOrderStatus(orderId, 'Entregado');
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.flag, size: 16),
                  label: const Text('Entregado'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Asignado':
        return Colors.blue;
      case 'En Camino':
        return Colors.orange;
      case 'Cerca':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
