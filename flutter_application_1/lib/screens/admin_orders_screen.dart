import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  Set<String> _selected = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() { _loading = true; });
    try {
      final resp = await http.post(
        Uri.parse(API_BASE_URL),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'action': 'get_all_orders', 'limit': 1000}),
      );
      if (resp.statusCode == 200) {
        // Intentar decodificar JSON; si no es el formato esperado, mostrar el body para depuración
        try {
          final decoded = json.decode(resp.body);
          if (decoded is Map && decoded['success'] == true && decoded['orders'] != null) {
            setState(() {
              _orders = List<Map<String, dynamic>>.from(decoded['orders'].map((e) => e is Map ? Map<String, dynamic>.from(e) : {'value': e}));
              _selected.clear();
            });
          } else {
            if (mounted) {
              final preview = resp.body.length > 300 ? resp.body.substring(0, 300) + '...' : resp.body;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Respuesta inesperada del servidor: $preview')));
            }
            setState(() { _orders = []; });
          }
        } catch (e) {
          if (mounted) {
            final preview = resp.body.length > 300 ? resp.body.substring(0, 300) + '...' : resp.body;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo decodificar JSON: $preview')));
          }
          setState(() { _orders = []; });
        }
      } else {
        if (mounted) {
          final preview = resp.body.length > 300 ? resp.body.substring(0, 300) + '...' : resp.body;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('HTTP ${resp.statusCode}: $preview')));
        }
        setState(() { _orders = []; });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cargando pedidos: $e')));
      setState(() { _orders = []; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _showOrderDetail(String orderId) async {
    try {
      final resp = await http.post(
        Uri.parse(API_BASE_URL),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'action': 'get_order_detail', 'order_id': orderId}),
      );
      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body);
        if (decoded is Map && decoded['success'] == true) {
          final pedido = decoded['pedido'];
          final items = decoded['items'] ?? [];
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text('Detalle pedido ${orderId}'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pedido: ${json.encode(pedido)}'),
                      const SizedBox(height: 12),
                      const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...List<Widget>.from((items as List).map((it) => ListTile(
                        dense: true,
                        title: Text(it['Nombre_Platillo'] ?? it['Nombre'] ?? it['name'] ?? ''),
                        subtitle: Text('Cantidad: ${it['Cantidad'] ?? it['cantidad'] ?? it['quantity'] ?? ''} • Precio: ${it['Precio'] ?? it['price'] ?? ''}'),
                      ))),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
              ],
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cargando detalle: $e')));
    }
  }

  Future<void> _deleteOrders(List<String> ids) async {
    if (ids.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar ${ids.length} pedido(s) de la base de datos? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final resp = await http.post(
        Uri.parse(API_BASE_URL),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'action': 'delete_orders', 'order_ids': ids}),
      );
      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body);
        if (decoded != null && decoded['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Eliminados: ${decoded['deleted'] ?? 0}')));
          // remover localmente
          setState(() {
            _orders.removeWhere((o) {
              final oid = (o['ID_Pedido'] ?? o['id'] ?? o['ID'] ?? o['order_id'] ?? '').toString();
              return ids.contains(oid);
            });
            _selected.clear();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error eliminando: ${decoded?['message'] ?? resp.body}')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('HTTP ${resp.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Pedidos'),
        actions: [
          IconButton(onPressed: _loadOrders, icon: const Icon(Icons.refresh)),
          IconButton(
            onPressed: _selected.isEmpty ? null : () => _deleteOrders(_selected.toList()),
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Eliminar seleccionados',
          ),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _orders.isEmpty
          ? Center(child: Text('No hay pedidos'))
          : ListView.builder(
              itemCount: _orders.length,
              itemBuilder: (context, i) {
                final o = _orders[i];
                final oid = (o['ID_Pedido'] ?? o['id'] ?? o['ID'] ?? o['order_id'] ?? '').toString();
                final cliente = (o['Cliente'] ?? o['cliente'] ?? o['Nombre'] ?? o['name'] ?? '').toString();
                final estado = (o['Estado_Pedido'] ?? o['estado'] ?? o['status'] ?? '').toString();
                return CheckboxListTile(
                  value: _selected.contains(oid),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) _selected.add(oid); else _selected.remove(oid);
                    });
                  },
                  title: Text('Pedido #$oid • $cliente'),
                  subtitle: Text('Estado: $estado'),
                  secondary: PopupMenuButton<String>(
                    onSelected: (act) async {
                      if (act == 'detail') await _showOrderDetail(oid);
                      if (act == 'delete') await _deleteOrders([oid]);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'detail', child: Text('Ver detalles')),
                      const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
