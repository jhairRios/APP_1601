import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';
import '../widgets/repartidores_list.dart';
import '../services/menu_service.dart';
import '../widgets/flexible_image.dart';
import '../widgets/product_image_box.dart';
import '../services/order_service.dart';
import 'order_confirmation.dart';

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

  Future<void> _showRepartidorDetails(Map<String, dynamic> r) async {
    final repId =
        r['ID_Repartidor'] ??
        r['id'] ??
        r['ID'] ??
        r['Id'] ??
        r['id_repartidor'];
    if (repId == null) {
      // mostrar dialog con info mínima
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Repartidor'),
          content: Text('No se pudo identificar el ID del repartidor.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      final resp = await http.post(
        Uri.parse(API_BASE_URL),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'get_repartidor_orders',
          'repartidor_id': repId,
        }),
      );
      if (resp.statusCode != 200) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Error'),
            content: const Text('Error al obtener pedidos.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
        return;
      }
      final decoded = json.decode(resp.body);
      List<dynamic> orders = [];
      if (decoded is Map && decoded['orders'] != null)
        orders = decoded['orders'];
      else if (decoded is List)
        orders = decoded;

      // Mostrar en dialog lista de pedidos asignados
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(
            'Pedidos de ${r['Nombre'] ?? r['nombre'] ?? 'Repartidor'}',
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: orders.isEmpty
                ? const Text('No hay pedidos asignados')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: orders.length,
                    itemBuilder: (context, i) {
                      final o = orders[i] as Map<String, dynamic>;
                      final id =
                          o['ID_Pedido'] ??
                          o['id'] ??
                          o['order_id'] ??
                          o['ID'] ??
                          o['Id'] ??
                          '—';
                      final cliente =
                          o['Cliente'] ?? o['cliente'] ?? o['customer'] ?? '';
                      final estado =
                          o['Estado_Pedido'] ??
                          o['estado'] ??
                          o['status'] ??
                          '';
                      return ListTile(
                        dense: true,
                        title: Text(_formatOrderLabel(id.toString())),
                        subtitle: Text(
                          '${cliente.toString()} • ${estado.toString()}',
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          // opcional: abrir detalle del pedido
                          try {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrderConfirmationScreen(
                                  orderId: id.toString(),
                                  mesa:
                                      o['Mesa'] ??
                                      o['mesa'] ??
                                      o['ubicacion'] ??
                                      null,
                                  telefono:
                                      o['Telefono'] ?? o['telefono'] ?? null,
                                ),
                              ),
                            );
                          } catch (_) {}
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text('Error: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  }

  // Devuelve el estado textual del platillo según el ID_Estado

  List<Map<String, dynamic>> categorias = <Map<String, dynamic>>[];
  int? categoriaSeleccionada;
  int? estadoSeleccionado;
  int _selectedIndex = 0;
  List<dynamic> _menuItems = [];
  late StreamSubscription<bool> _menuSubscription;
  late StreamSubscription<Map<String, dynamic>> _orderSubscription;
  List<Map<String, dynamic>> _recentOrders = [];
  bool _showHistory = false; // false = hide delivered by default
  String _statusFilter = 'Todos';
  int _pendingOrderCount = 0; // contador de pedidos nuevos no leídos
  Timer? _pollTimer;
  List<Map<String, dynamic>> _repartidores = [];

  @override
  void initState() {
    super.initState();
    _fetchCategorias();
    // Cargar preferencia de mostrar historial (persistida)
    _loadShowHistory();
    _fetchMenuItems();
    // Suscribirse a cambios en el menú para refrescar automáticamente
    _menuSubscription = MenuService.menuChangeController.stream.listen((_) {
      _fetchMenuItems();
    });
    // Escuchar nuevos pedidos creados en la app (cliente)
    _orderSubscription = OrderService.orderStream.listen((order) {
      try {
        // Debug print when empleado receives an order
        // ignore: avoid_print
        print('empleado: received order -> ${order.toString()}');

        if (!mounted) return;
        // Insertar de forma segura (si order no es Map, lo ignoramos)
        Map<String, dynamic>? safeOrder;
        try {
          safeOrder = Map<String, dynamic>.from(order);
        } catch (_) {
          safeOrder = null;
        }

        setState(() {
          if (safeOrder != null) {
            final normalized = _normalizeOrder(safeOrder);
            // evitar duplicados por order_id; si existe, actualizar el registro
            final incomingId = normalized['order_id']?.toString();
            final idx = _recentOrders.indexWhere((r) => r['order_id']?.toString() == incomingId);
            if (idx == -1) {
              _recentOrders.insert(0, normalized);
              // Incrementar contador de pedidos pendientes solo si es nuevo
              _pendingOrderCount = (_pendingOrderCount) + 1;
            } else {
              _recentOrders[idx] = normalized;
            }
          }
        });
        // Persistir cache local de pedidos recientes
        try { _saveRecentOrdersCache(); } catch (_) {}

        // Mostrar SnackBar de notificación en un post-frame callback para evitar
        // problemas si el Scaffold aún no está totalmente montado.
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Nuevo pedido recibido (${_pendingOrderCount.toString()})',
                  ),
                  duration: const Duration(seconds: 3),
                  action: SnackBarAction(
                    label: 'Ver',
                    onPressed: () {
                      if (!mounted) return;
                      setState(() {
                        _selectedIndex = 2; // ir a Pedidos
                        _pendingOrderCount = 0; // marcar como leído al verlo
                      });
                    },
                  ),
                ),
              );
            } catch (_) {}
          });
        }
      } catch (e) {
        // ignore: avoid_print
        print('empleado: order subscription error: $e');
      }
    });
    // Cargar cache local de pedidos recientes (si existe), antes de empezar polling
    _loadRecentOrdersCache().then((_) {
      // Iniciar polling periódico para detectar pedidos pendientes desde el servidor
      _startPolling();
    });
    // Cargar lista de repartidores inicialmente
    _loadRepartidores();
  }

  @override
  void dispose() {
    try {
      _menuSubscription.cancel();
      _orderSubscription.cancel();
      _stopPolling();
    } catch (_) {}
    super.dispose();
  }

  void _startPolling() {
    try {
      // Ejecutar una comprobación inmediata y luego periódicamente
      _pollPendingOrders();
      _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _pollPendingOrders();
      });
    } catch (e) {
      // ignore: avoid_print
      print('empleado: error starting poll: $e');
    }
  }

  void _stopPolling() {
    try {
      _pollTimer?.cancel();
      _pollTimer = null;
    } catch (_) {}
  }

  Future<void> _pollPendingOrders() async {
    try {
      final resp = await http.post(
        Uri.parse(API_BASE_URL),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'action': 'get_pending_orders', 'include_assigned': true}),
      );
      // Debug: print response status and body to help troubleshooting
      try {
        // ignore: avoid_print
        print('[empleado] _pollPendingOrders: status=${resp.statusCode} body=${resp.body}');
      } catch (_) {}
      if (resp.statusCode != 200) return;
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
      }

      if (ordersRaw.isEmpty) return;
      try {
        // ignore: avoid_print
        print('[empleado] _pollPendingOrders: fetched ${ordersRaw.length} ordersRaw entries');
      } catch (_) {}

      // Normalize and merge new orders into _recentOrders avoiding duplicates
      final fetched = List<Map<String, dynamic>>.from(
        ordersRaw.map(
          (e) => e is Map ? Map<String, dynamic>.from(e) : {'value': e},
        ),
      );

      int newCount = 0;
      setState(() {
        for (final o in fetched.reversed) {
          final normalized = _normalizeOrder(Map<String, dynamic>.from(o));
          final oid = normalized['order_id']?.toString();
          final exists =
              oid != null &&
              _recentOrders.any((r) => r['order_id']?.toString() == oid);
          if (!exists) {
            _recentOrders.insert(0, normalized);
            newCount++;
          }
        }
        if (newCount > 0) {
          _pendingOrderCount = (_pendingOrderCount) + newCount;
        }
      });
      if (newCount > 0) {
        try { _saveRecentOrdersCache(); } catch (_) {}
      }

      // Refrescar repartidores también para mantener contadores actualizados
      _loadRepartidores();
    } catch (e) {
      // ignore: avoid_print
      print('empleado: poll error: $e');
    }
  }

  Future<void> _loadRepartidores() async {
    try {
      final resp = await http.post(
        Uri.parse(API_BASE_URL),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'action': 'get_repartidores'}),
      );
      if (resp.statusCode != 200) return;
      final decoded = json.decode(resp.body);
      List<dynamic> reps = [];
      if (decoded is Map && decoded['repartidores'] != null)
        reps = decoded['repartidores'];
      else if (decoded is List)
        reps = decoded;

      final list = List<Map<String, dynamic>>.from(
        reps.map((e) => e is Map ? Map<String, dynamic>.from(e) : {'value': e}),
      );
      if (!mounted) return;
      setState(() {
        _repartidores = list;
      });
    } catch (e) {
      // ignore: avoid_print
      print('empleado: load repartidores error: $e');
    }
  }

  // Persistir/recuperar cache local de pedidos recientes para mantener estado
  Future<void> _saveRecentOrdersCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'empleado_recent_orders';
      final list = _recentOrders.map((e) => json.encode(e)).toList();
      await prefs.setStringList(key, list);
    } catch (e) {
      // ignore
    }
  }

  // Persistir la preferencia de mostrar historial entre sesiones
  Future<void> _loadShowHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'empleado_show_history';
      final val = prefs.getBool(key) ?? false;
      if (!mounted) return;
      setState(() {
        _showHistory = val;
      });
    } catch (e) {
      // ignore
    }
  }

  Future<void> _saveShowHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'empleado_show_history';
      await prefs.setBool(key, _showHistory);
    } catch (e) {
      // ignore
    }
  }

  void _toggleShowHistory() {
    setState(() {
      _showHistory = !_showHistory;
    });
    try {
      _saveShowHistory();
    } catch (_) {}
    // If turning on history, fetch historical orders from server (admin endpoint)
    if (_showHistory) {
      _loadHistoryOrders();
    } else {
      // when hiding history, refresh pending orders from server
      _pollPendingOrders();
    }
  }

  // Cargar pedidos históricos (entregados) usando el endpoint admin `get_all_orders`
  Future<void> _loadHistoryOrders() async {
    try {
      final resp = await http.post(
        Uri.parse(API_BASE_URL),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'action': 'get_all_orders', 'limit': 1000}),
      );
      if (resp.statusCode != 200) return;
      final decoded = json.decode(resp.body);
      List<dynamic> ordersRaw = [];
      if (decoded is Map && decoded['orders'] != null) ordersRaw = decoded['orders'];
      else if (decoded is List) ordersRaw = decoded;
      if (ordersRaw.isEmpty) return;

      final fetched = List<Map<String, dynamic>>.from(
        ordersRaw.map((e) => e is Map ? Map<String, dynamic>.from(e) : {'value': e}),
      );

      // Keep only delivered/cancelled (history) entries
      final history = <Map<String, dynamic>>[];
      for (final o in fetched) {
        try {
          final norm = _normalizeOrder(Map<String, dynamic>.from(o));
          if (_isDelivered(norm)) history.add(norm);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        // Replace recent orders list with history entries (most recent first)
        _recentOrders = history;
      });
      try { _saveRecentOrdersCache(); } catch (_) {}
    } catch (e) {
      // ignore
    }
  }

  Future<void> _loadRecentOrdersCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'empleado_recent_orders';
      final list = prefs.getStringList(key) ?? [];
      final loaded = <Map<String, dynamic>>[];
      for (final s in list) {
        try {
          final m = json.decode(s);
          if (m is Map<String, dynamic>) loaded.add(m);
        } catch (_) {}
      }
      if (loaded.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          // merge loaded entries at the front, avoiding duplicates
          for (final e in loaded.reversed) {
            final oid = e['order_id']?.toString();
            if (oid == null) continue;
            final exists = _recentOrders.any((r) => r['order_id']?.toString() == oid);
            if (!exists) _recentOrders.insert(0, e);
          }
        });
      }
    } catch (e) {
      // ignore
    }
  }

  String _formatOrderLabel(String raw) {
    final s = raw.toString();
    if (s.toLowerCase().startsWith('pedido')) return s;
    if (s.startsWith('#')) return 'Pedido $s';
    return 'Pedido #$s';
  }

  Widget _buildInteractiveStatusBar(Map<String, dynamic> order) {
    final List<String> steps = [
      'Confirmado',
      'Preparando',
      'En Camino',
      'Entregado',
    ];
    final current =
        (order['status'] ??
                order['Estado_Pedido'] ??
                order['estado'] ??
                order['status_label'] ??
                '')
            .toString();
    int currentIndex = steps.indexOf(current);
    if (currentIndex < 0) {
      // try mapping common alternatives
      final low = current.toLowerCase();
      if (low.contains('pend'))
        currentIndex = 0;
      else if (low.contains('prepar'))
        currentIndex = 1;
      else if (low.contains('camino') ||
          low.contains('entrega') ||
          low.contains('en camino'))
        currentIndex = 2;
      else if (low.contains('entreg'))
        currentIndex = 3;
      else
        currentIndex = 0;
    }

    return Row(
      children: steps.asMap().entries.map((entry) {
        final idx = entry.key;
        final label = entry.value;
        final isActive = idx <= currentIndex;
        return Expanded(
          child: GestureDetector(
            onTap: () async {
              try {
                final orderId =
                    (order['order_id'] ??
                            order['ID_Pedido'] ??
                            order['id'] ??
                            order['ID'] ??
                            '')
                        .toString();
                await _updateOrderStatus(orderId, label);
              } catch (e) {
                // ignore
              }
            },
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: isActive
                      ? const Icon(Icons.check, color: Colors.white, size: 12)
                      : null,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? Colors.black : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                if (idx < steps.length - 1)
                  Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 12,
                    ),
                    color: idx < currentIndex ? Colors.green : Colors.grey[300],
                    width: double.infinity,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      final sanitizedOrderId = orderId.toString().replaceAll(
        RegExp(r'[^0-9]'),
        '',
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
      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body);
        if (decoded != null && decoded['success'] == true) {
          // actualizar orden localmente
          setState(() {
            final idx = _recentOrders.indexWhere(
              (r) =>
                  (r['order_id']?.toString() ??
                      r['ID_Pedido']?.toString() ??
                      '') ==
                  sanitizedOrderId,
            );
            if (idx >= 0) {
              _recentOrders[idx]['status'] = status;
            }
          });
          try { _saveRecentOrdersCache(); } catch (_) {}
          // Notificar a otras pantallas en la app
          try {
            final notify = {'order_id': sanitizedOrderId, 'status': status};
            OrderService.notifyNewOrder(notify);
          } catch (_) {}
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Estado actualizado: $status')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se pudo actualizar: ${resp.body}')),
          );
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('HTTP ${resp.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error de red: $e')));
    }
  }

  // Normaliza diferentes formatos de pedidos entrantes a un mapa con claves estandarizadas
  Map<String, dynamic> _normalizeOrder(Map<String, dynamic> src) {
    final m = <String, dynamic>{};

    String? pickFirst(List<String> candidates) {
      for (final k in candidates) {
        if (src.containsKey(k) && src[k] != null) return src[k].toString();
      }
      // try lowercase keys
      for (final entry in src.entries) {
        final lk = entry.key.toString().toLowerCase();
        for (final k in candidates) {
          if (lk == k.toLowerCase()) return entry.value?.toString();
        }
      }
      return null;
    }

    // order id
    final id = pickFirst([
      'order_id',
      'ID_Pedido',
      'ID_Pedidos',
      'id_pedido',
      'id',
      'ID',
      'pedido_id',
    ]);
    m['order_id'] =
        id ??
        src.values
            .map((e) => e?.toString())
            .firstWhere((_) => true, orElse: () => null);

    // customer / nombre
    var customer = pickFirst([
      'customer',
      'cliente',
      'nombre',
      'name',
      'usuario',
      'nombre_usuario',
      'nombre_cliente',
      'user_name',
      'email',
    ]);
    // sanitize accidental file paths or screenclip strings
    if (customer != null) {
      final lower = customer.toLowerCase();
      if (customer.contains('\\') ||
          lower.contains('screencap') ||
          lower.contains('screenclip') ||
          RegExp(r'^[a-zA-Z]:\\').hasMatch(customer)) {
        customer = null;
      }
    }
    m['customer'] = customer ?? 'Cliente';

    // table / mesa
    m['table'] =
        pickFirst(['table', 'mesa', 'numero_mesa', 'mesa_numero']) ?? '';

    // ubicacion / direccion
    m['ubicacion'] =
        pickFirst([
          'ubicacion',
          'direccion',
          'direccion_entrega',
          'direccion_envio',
          'address',
        ]) ??
        '';

    // state/status
    m['status'] =
        pickFirst(['status', 'estado', 'estado_pedido']) ??
        src['status']?.toString() ??
        'Pendiente';

    // total
    m['total'] =
        pickFirst(['total', 'monto', 'precio', 'Total']) ?? src['total'];

    // payment method
    m['payment_method'] =
        pickFirst(['payment_method', 'metodo_pago', 'pago', 'payment']) ?? '';

    // preserve other keys just in case
    for (final entry in src.entries) {
      if (!m.containsKey(entry.key)) m[entry.key] = entry.value;
    }

    return m;
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
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
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
      categoriaActual = firstId is int
          ? firstId
          : int.tryParse(firstId.toString());
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
                                  final XFile? picked = await _picker.pickImage(
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
                        const SizedBox(height: 12),
                        // Campo URL imagen
                        TextField(
                          controller: imagenController,
                          style: TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            hintText: 'URL de imagen (opcional)',
                            prefixIcon: Icon(Icons.image, color: colorPrimario),
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
                          value:
                              categorias.any((cat) {
                                final id = cat['ID_Categoria'];
                                final catId = id is int
                                    ? id
                                    : int.tryParse(id.toString());
                                return catId == categoriaActual;
                              })
                              ? categoriaActual
                              : null,
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

                              print('🔄 Actualizando platillo ID: $idMenu');

                              Map<String, dynamic> datosActualizados = {
                                'ID_Menu': idMenu,
                                'Platillo': nombreController.text.trim(),
                                'Precio': precioController.text.trim(),
                                'Descripcion': descripcionController.text
                                    .trim(),
                                'ID_Categoria': categoriaActual,
                                'ID_Estado': estadoActual,
                              };

                              // Solo incluir Imagen si cambió y no está vacía
                              final nuevaImagen = imagenController.text.trim();
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
            style: TextStyle(fontWeight: FontWeight.bold, color: colorPrimario),
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

                  final success = await MenuService.deleteMenuItem(idMenu ?? 0);

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
                      final intId = id is int
                          ? id
                          : int.tryParse(id.toString());
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
                                  final intId = id is int
                                      ? id
                                      : int.tryParse(id.toString());
                                  return DropdownMenuItem<int>(
                                    value: intId,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.category,
                                          color: _modalPrimary,
                                        ),
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
                                success =
                                    await MenuService.addMenuItemWithImage(
                                      {
                                        'Platillo': nombreController.text,
                                        'Precio': precioController.text,
                                        'Descripcion':
                                            descripcionController.text,
                                        'ID_Categoria': selectedCategoriaId,
                                        'ID_Estado': selectedEstadoId,
                                      },
                                      imageBytes: imagenBytes,
                                      imageFilename:
                                          imagenFilename ?? 'imagen.jpg',
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
            if (index == 2) {
              // Ver pedidos: marcar como leídos
              _pendingOrderCount = 0;
            }
          });
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Menú',
          ),
          BottomNavigationBarItem(icon: _buildOrderIcon(), label: 'Pedidos'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.delivery_dining),
            label: 'Repartidores',
          ),
        ],
      ),
    );
  }

  // Icono de Pedidos con contador (badge)
  Widget _buildOrderIcon() {
    if (_pendingOrderCount <= 0) {
      return const Icon(Icons.shopping_cart);
    }

    // Mostrar icono con badge
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.shopping_cart),
        Positioned(
          right: -6,
          top: -6,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            child: Center(
              child: Text(
                _pendingOrderCount > 99 ? '99+' : _pendingOrderCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
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
          // Ya no usamos altura fija para info; Expanded evita desbordes.

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

                // Información (usa Expanded para evitar desbordes)
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

  // ✅ TOMAR PEDIDOS
  Widget _buildTomarPedidos(Color colorPrimario, Color colorNaranja) {
    // preparar lista mostrada: por defecto ocultar entregados; si _showHistory==true
    // mostrar sólo pedidos entregados (historial)
    bool matchesFilter(Map<String, dynamic> src) {
      try {
        final n = _normalizeOrder(Map<String, dynamic>.from(src));
        final statusRaw = (n['status'] ?? '').toString().toLowerCase();
        final low = statusRaw;
        if (_statusFilter == 'Todos') return true;
        switch (_statusFilter) {
          case 'Pendientes':
            return low.contains('pend') || low.contains('confirm');
          case 'En Preparación':
            return low.contains('prepar');
          case 'Listos':
            return low.contains('listo');
          case 'En Entrega':
            return low.contains('camino') || low.contains('entreg') || low.contains('en camino');
          case 'Entregados':
            return _isDelivered(n);
          case 'Cancelados':
            return low.contains('cancel');
          default:
            return true;
        }
      } catch (_) {
        return true;
      }
    }

    final List<Map<String, dynamic>> displayOrders = _recentOrders.where((o) {
      try {
        final n = _normalizeOrder(Map<String, dynamic>.from(o));
        if (_showHistory) {
          // when showing history, ignore the status filter and show delivered orders
          return _isDelivered(n);
        } else {
          return !_isDelivered(n) && matchesFilter(o);
        }
      } catch (_) {
        return true;
      }
    }).toList();

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

              // Filtros de estado con mejor scroll + botón refrescar
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          _buildStatusChip('Todos', colorPrimario),
                          const SizedBox(width: 8),
                          _buildStatusChip('Pendientes', colorNaranja),
                          const SizedBox(width: 8),
                          _buildStatusChip('En Preparación', Colors.blue),
                          const SizedBox(width: 8),
                          _buildStatusChip('Listos', Colors.green),
                          const SizedBox(width: 8),
                          _buildStatusChip('En Entrega', Colors.purple),
                          const SizedBox(width: 8),
                          _buildStatusChip('Entregados', Colors.grey),
                          const SizedBox(width: 8),
                          _buildStatusChip('Cancelados', Colors.red),
                          const SizedBox(width: 8),
                          _buildStatusChip('Historial', Colors.teal),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      // refrescar manualmente (traer desde servidor)
                      _pollPendingOrders();
                      _loadRepartidores();
                    },
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refrescar pedidos',
                  ),
                ],
              ),

          const SizedBox(height: 20),

          const SizedBox(height: 8),

          // Lista de pedidos (primero pedidos recientes desde OrderService)
          displayOrders.isNotEmpty
              ? Column(
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      _showHistory ? 'Historial de entregados' : 'Pedidos recientes',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: displayOrders.map((o) {
                        final normalized = _normalizeOrder(Map<String, dynamic>.from(o));
                        final orderNumber =
                            normalized['order_id']?.toString() ?? 'Pedido';
                        final customer =
                            normalized['customer']?.toString() ?? 'Cliente';
                        final table = normalized['table']?.toString() ?? '';
                        final ubicacion = normalized['ubicacion']?.toString() ?? '';
                        final isDelivery = ubicacion.isNotEmpty;
                        final status = normalized['status']?.toString() ?? 'Pendiente';
                        final total = normalized['total'] != null
                            ? '\$${normalized['total']}'
                            : '\$0.00';
                        final payment = normalized['payment_method']?.toString() ?? '';
                        return _buildOrderCard(
                          orderNumber,
                          customer,
                          isDelivery ? ubicacion : table,
                          status,
                          total,
                          isDelivery,
                          colorPrimario,
                          colorNaranja,
                          payment,
                          normalized,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                )
              : const SizedBox.shrink(),

          // Lista simulada (sólo mostrar si no hay pedidos reales en displayOrders)
          displayOrders.isEmpty
              ? ListView.builder(
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
                      false,
                      colorPrimario,
                      colorNaranja,
                      '',
                      null,
                    );
                  },
                )
              : const SizedBox.shrink(),
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

          // Lista dinámica de repartidores cargada desde la BD
          RepartidoresList(
            showPhone: true,
            onTapRepartidor: (r) {
              _showRepartidorDetails(r);
            },
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

  Widget _buildStatusChip(String label, Color color) {
    final bool isSelected = label == 'Historial' ? _showHistory : (_statusFilter == label);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (label == 'Historial') {
            _toggleShowHistory();
          } else {
            _statusFilter = label;
            // when selecting normal filters, hide historial
            _showHistory = false;
            _saveShowHistory();
          }
        });
      },
      child: Container(
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
      ),
    );
  }

  bool _isDelivered(Map<String, dynamic> normalized) {
    final raw = (normalized['status'] ?? normalized['Estado_Pedido'] ?? normalized['estado'] ?? '') .toString();
    final low = raw.toLowerCase().trim();
    if (low.isEmpty) return false;
    // numeric '3' often represents delivered
    final maybeNum = int.tryParse(low);
    if (maybeNum != null && maybeNum == 3) return true;
    if (low.contains('entreg') || low.contains('finaliz') || low.contains('cancel')) {
      // 'entreg' covers 'entregado', 'entrega'
      return low.contains('entreg');
    }
    return low == 'entregado' || low == 'finalizado';
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
    bool isDelivery,
    Color colorPrimario,
    Color colorNaranja,
    String? paymentMethod,
    Map<String, dynamic>? rawOrder,
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
                _formatOrderLabel(orderNumber),
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
          if (table.isNotEmpty) ...[
            if (isDelivery) Text('Ubicación: $table') else Text('Mesa: $table'),
          ],
          if (paymentMethod != null && paymentMethod.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Pago: $paymentMethod',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
          const SizedBox(height: 12),
          // Barra de estado interactiva para empleados
          _buildInteractiveStatusBar(
            rawOrder ?? {'status': status, 'order_id': orderNumber},
          ),
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
                  // Ver detalles del pedido: abrir pantalla de detalles con la información disponible
                  try {
                    final items = rawOrder != null
                        ? List<dynamic>.from(rawOrder['items'] ?? [])
                        : <dynamic>[];
                    final double parsedTotal = (() {
                      try {
                        final t = rawOrder != null
                            ? (rawOrder['total'] ?? rawOrder['Total'])
                            : null;
                        if (t == null) return 0.0;
                        return double.tryParse(t.toString()) ?? 0.0;
                      } catch (_) {
                        return 0.0;
                      }
                    })();
                    final ubic = rawOrder != null
                        ? (rawOrder['ubicacion'] ??
                                  rawOrder['Ubicacion'] ??
                                  rawOrder['direccion'] ??
                                  '')
                              .toString()
                        : '';
                    final telefono = rawOrder != null
                        ? (rawOrder['telefono'] ??
                                  rawOrder['Telefono'] ??
                                  rawOrder['phone'] ??
                                  '')
                              .toString()
                        : '';
                    final mesa = rawOrder != null
                        ? (rawOrder['table'] ??
                                  rawOrder['mesa'] ??
                                  rawOrder['Mesa'] ??
                                  '')
                              .toString()
                        : '';
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrderConfirmationScreen(
                          orderId: orderNumber,
                          items: items,
                          total: parsedTotal,
                          ubicacion: ubic,
                          telefono: telefono,
                          mesa: mesa,
                        ),
                      ),
                    );
                  } catch (e) {
                    // ignore: avoid_print
                    print('empleado: error opening details $e');
                  }
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

  Widget _buildRepartidorCardFromData(Map<String, dynamic> r, Color colorAzul) {
    final name =
        (r['Nombre'] ??
                r['nombre'] ??
                r['name'] ??
                r['ID_Repartidor'] ??
                r['ID'] ??
                'Repartidor')
            .toString();
    final estadoRaw = r['Estado_Repartidor'] ?? r['estado'] ?? r['status'] ?? 0;
    final bool disponible =
        (estadoRaw.toString() == '1' ||
        estadoRaw.toString().toLowerCase() == '1' ||
        estadoRaw.toString().toLowerCase() == 'disponible');
    final assigned =
        r['assigned_count'] ?? r['assigned'] ?? r['assignedCount'] ?? 0;
    final statusLabel = disponible ? 'Disponible' : 'Ocupado';

    return InkWell(
      onTap: () => _showRepartidorDetails(r),
      child: Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: disponible
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      color: disponible ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${assigned.toString()} pedidos',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
                  _formatOrderLabel(orderNumber),
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
