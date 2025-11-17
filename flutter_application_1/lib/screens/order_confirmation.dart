import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_config.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final dynamic orderId;
  final List<dynamic>? items;
  final double? total;
  final String? ubicacion;
  final String? telefono;
  final String? mesa;

  const OrderConfirmationScreen({
    Key? key,
    required this.orderId,
    this.items,
    this.total,
    this.ubicacion,
    this.telefono,
    this.mesa,
  }) : super(key: key);

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  bool _loading = true;
  List<dynamic> _items = [];
  double _total = 0.0;
  String _ubicacion = '';
  String _telefono = '';
  String _mesa = '';

  @override
  void initState() {
    super.initState();
    // Si tenemos orderId, intentar obtener el detalle oficial del servidor
    if (widget.orderId != null) {
      _fetchOrderDetail(widget.orderId);
    } else {
      _items = widget.items ?? [];
      _total = widget.total ?? 0.0;
      _ubicacion = widget.ubicacion ?? '';
      _telefono = widget.telefono ?? '';
      _loading = false;
    }
  }

  Future<void> _fetchOrderDetail(dynamic orderId) async {
    setState(() {
      _loading = true;
    });
    try {
      final payload = {'action': 'get_order_detail', 'order_id': orderId};
      final resp = await http.post(
        Uri.parse(API_BASE_URL),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body);
        if (decoded != null && decoded['success'] == true) {
          final pedido = decoded['pedido'] ?? {};
          final items = decoded['items'] ?? [];
          double totalFromPedido = 0.0;
          if (isset(pedido['Total']) || isset(pedido['total'])) {
            totalFromPedido = (pedido['Total'] ?? pedido['total']) + 0.0;
          } else {
            // Calcular a partir de items
            for (var it in items) {
              final price = (it['Precio'] ?? it['price'] ?? 0) + 0.0;
              final qty =
                  int.tryParse(
                    (it['Cantidad'] ?? it['quantity'] ?? 1).toString(),
                  ) ??
                  1;
              totalFromPedido += price * qty;
            }
          }

          setState(() {
            _items = items;
            _total = totalFromPedido;
            _ubicacion =
                (pedido['Ubicacion'] ??
                    pedido['ubicacion'] ??
                    widget.ubicacion) ??
                '';
            _mesa = (pedido['Mesa'] ?? pedido['mesa'] ?? widget.mesa) ?? '';
            _telefono =
                (pedido['Telefono'] ?? pedido['telefono'] ?? widget.telefono) ??
                '';
            _loading = false;
          });
          return;
        }
      }
      // Si no fue posible obtener del servidor, fallback a los datos pasados
        setState(() {
        _items = widget.items ?? [];
        _total = widget.total ?? 0.0;
        _ubicacion = widget.ubicacion ?? '';
        _telefono = widget.telefono ?? '';
        _mesa = widget.mesa ?? '';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _items = widget.items ?? [];
        _total = widget.total ?? 0.0;
        _ubicacion = widget.ubicacion ?? '';
        _telefono = widget.telefono ?? '';
        _loading = false;
      });
    }
  }

  bool isset(dynamic v) => v != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmación de Pedido')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedido ID: ${widget.orderId ?? '-'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_ubicacion.isNotEmpty)
                    Text('Dirección: ${_ubicacion}')
                  else if (_mesa.isNotEmpty)
                    Text('Mesa: ${_mesa}')
                  else
                    Text('Dirección/Mesa: -'),
                  const SizedBox(height: 4),
                  Text('Teléfono: ${_telefono.isNotEmpty ? _telefono : '-'}'),
                  const SizedBox(height: 12),
                  const Text(
                    'Items:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final it = _items[index];
                        final name =
                            it['name'] ??
                            it['Nombre_Platillo'] ??
                            it['Nombre'] ??
                            '';
                        final qty = it['quantity'] ?? it['Cantidad'] ?? 1;
                        final price = (it['price'] ?? it['Precio'] ?? 0) + 0.0;
                        final qtyNum = qty is int
                            ? qty
                            : int.tryParse(qty.toString()) ?? 1;
                        return ListTile(
                          title: Text(name),
                          subtitle: Text('Cantidad: $qtyNum'),
                          trailing: Text(
                            '\$${(price * qtyNum).toStringAsFixed(2)}',
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${_total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Volver a la vista previa (mantener el contexto/rol actual).
                        // Si hay una ruta previa en la pila, simplemente hacer pop.
                        // Si no hay previas (caso raro), reemplazamos por '/menu' como último recurso.
                        try {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            Navigator.of(context).pushReplacementNamed('/menu');
                          }
                        } catch (_) {
                          // Fallback más seguro: intentar popUntil al primer route
                          try { Navigator.of(context).popUntil((route) => route.isFirst); } catch (_) {}
                        }
                      },
                      child: const Text('Volver al menú'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
