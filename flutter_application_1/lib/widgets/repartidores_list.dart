import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_config.dart';

class RepartidoresList extends StatefulWidget {
  final bool showPhone;
  final void Function(Map<String, dynamic>)? onTapRepartidor;
  const RepartidoresList({
    Key? key,
    this.showPhone = false,
    this.onTapRepartidor,
  }) : super(key: key);

  @override
  State<RepartidoresList> createState() => _RepartidoresListState();
}

class _RepartidoresListState extends State<RepartidoresList> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _reps = [];
  String? _lastRawResponse;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await http.post(
        Uri.parse(API_BASE_URL),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'action': 'get_repartidores'}),
      );
      if (resp.statusCode != 200) {
        setState(() {
          _error = 'HTTP ${resp.statusCode}';
          _loading = false;
        });
        return;
      }
      final bodyText = resp.body;
      // store raw response for debugging when needed
      _lastRawResponse = bodyText;
      // print to console for developer debugging
      // ignore: avoid_print
      print('Repartidores API response: $bodyText');
      final decoded = json.decode(bodyText);
      List<dynamic> list = [];
      if (decoded is Map && decoded['repartidores'] != null)
        list = decoded['repartidores'];
      else if (decoded is List)
        list = decoded;
      else if (decoded is Map) {
        for (final v in decoded.values) {
          if (v is List) {
            list = v;
            break;
          }
        }
      }
      final mapped = list.map<Map<String, dynamic>>((e) {
        if (e is Map) return Map<String, dynamic>.from(e);
        return {'value': e};
      }).toList();
      if (!mounted) return;
      setState(() {
        _reps = mapped;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _nameFrom(Map<String, dynamic> r) {
    final v = r['Nombre'] ?? r['nombre'] ?? r['name'] ?? r['ID_Repartidor'];
    if (v == null) return 'Repartidor';
    return v.toString();
  }

  String _phoneFrom(Map<String, dynamic> r) {
    final v = r['Telefono'] ?? r['telefono'] ?? r['phone'];
    if (v == null) return '';
    return v.toString();
  }

  int _stateFrom(Map<String, dynamic> r) {
    final v =
        r['Estado_Repartidor'] ??
        r['estado_repartidor'] ??
        r['estado'] ??
        r['Estado'] ??
        r['EstadoRepartidor'];
    if (v == null) return 0;
    if (v is int) return v;
    final s = v.toString();
    return int.tryParse(s) ?? (s.toLowerCase().contains('ruta') ? 1 : 0);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Error cargando repartidores'),
            const SizedBox(height: 8),
            Text(_error ?? ''),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_reps.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            const Text('No hay repartidores disponibles.'),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Refrescar'),
            ),
            if (_lastRawResponse != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Respuesta servidor: ' +
                      (_lastRawResponse!.length > 200
                          ? _lastRawResponse!.substring(0, 200) + '...'
                          : _lastRawResponse!),
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: _reps.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final r = _reps[index];
          final name = _nameFrom(r).toString();
          final phone = _phoneFrom(r).toString();
          final state = _stateFrom(r);
          final available = state == 0;
          return GestureDetector(
            onTap: () => widget.onTapRepartidor?.call(r),
            child: Container(
              width: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue.shade50,
                    child: const Icon(Icons.person, color: Colors.blue),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: available
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      available ? 'Disponible' : 'En ruta',
                      style: TextStyle(
                        color: available
                            ? Colors.green.shade800
                            : Colors.orange.shade800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (widget.showPhone && phone.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      phone,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
