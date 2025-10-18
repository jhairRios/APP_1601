import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

// FlexibleImage: versión simplificada.
// Ahora asume que `source` (o `name`) puede ser:
// - una URL (http/https) -> Image.network
// - un nombre simple sin extensión (ej. 'Coca_Cola') -> prueba assets/Menu/<name>.(png|jpg|jpeg)
// - una ruta/filename con extensión -> se usa tal cual
class FlexibleImage extends StatefulWidget {
  final String? source;
  final String? name;
  final BoxFit fit;
  final double? width;
  final double? height;

  const FlexibleImage({
    Key? key,
    this.source,
    this.name,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  State<FlexibleImage> createState() => _FlexibleImageState();
}

class _FlexibleImageState extends State<FlexibleImage> {
  List<String> _candidates = [];
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _prepareCandidates();
  }

  Future<void> _prepareCandidates() async {
    final raw = (widget.source ?? widget.name ?? '').toString().trim();
    if (raw.isEmpty) {
      setState(() => _candidates = []);
      return;
    }

    // URL -> single candidate
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      setState(() => _candidates = [raw]);
      return;
    }

    // If contains a dot but no slash: filename with extension (e.g. 'Hamburguesa.png')
    // Treat it as an asset in assets/Menu/ first, then as assets/<filename> fallback.
    if (raw.contains('.') && !raw.contains('/')) {
      final filename = raw;
      final list = <String>['assets/Menu/$filename', 'assets/$filename'];
      final existing = await _filterByManifest(list);
      setState(() => _candidates = existing.isNotEmpty ? existing : list);
      return;
    }

    // If contains a slash (path), assume it's a relative path; prefix assets/ if missing
    if (raw.contains('/')) {
      var candidate = raw.startsWith('assets/') ? raw : 'assets/$raw';
      candidate = candidate.replaceAll('%2520', '%20');
      final list = <String>[candidate];
      final existing = await _filterByManifest(list);
      setState(() => _candidates = existing.isNotEmpty ? existing : list);
      return;
    }

    // Bare name: try common extensions in assets/Menu/
    final exts = ['png', 'jpg', 'jpeg'];
    final list = exts.map((e) => 'assets/Menu/$raw.$e').toList();
    final existing = await _filterByManifest(list);
    setState(() => _candidates = existing.isNotEmpty ? existing : list);
  }

  Future<List<String>> _filterByManifest(List<String> candidates) async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent) as Map<String, dynamic>;
      final found = <String>[];
      // exact matches first
      for (final c in candidates) {
        if (manifestMap.containsKey(c)) found.add(c);
      }
      if (found.isNotEmpty) {
        // ignore: avoid_print
        print('[FlexibleImage] manifest exact matches=${found.join(', ')}');
        return found;
      }
      // fallback: try suffix matches (some manifests may contain different prefixes)
      for (final c in candidates) {
        final keySuffix = c.startsWith('assets/') ? c.substring('assets/'.length) : c;
        for (final key in manifestMap.keys) {
          if (key.endsWith(keySuffix)) {
            found.add(key);
          }
        }
        if (found.isNotEmpty) break;
      }
      if (found.isNotEmpty) {
        // ignore: avoid_print
        print('[FlexibleImage] manifest suffix matches=${found.join(', ')}');
      } else {
        // ignore: avoid_print
        print('[FlexibleImage] manifest no matches for candidates=${candidates.join(', ')}');
      }
      return found;
    } catch (e) {
      // If can't read manifest, return empty list so caller falls back to original
      return [];
    }
  }

  Widget _placeholder() => Container(
        width: widget.width,
        height: widget.height,
        color: Colors.transparent,
        child: Icon(Icons.restaurant, color: Colors.grey[400], size: (widget.width ?? 40)),
      );

  @override
  Widget build(BuildContext context) {
    if (_candidates.isEmpty) return _placeholder();
    final cur = _candidates[_index];

    if (cur.startsWith('http://') || cur.startsWith('https://')) {
      return Image.network(
        cur,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          if (_index < _candidates.length - 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _index++);
            });
          }
          return _placeholder();
        },
      );
    }

    // For Image.asset on web, pass the key without a leading 'assets/' (Image.asset will map correctly)
    final assetKey = cur.startsWith('assets/') ? cur.substring('assets/'.length) : cur;
    return Image.asset(
      assetKey,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        if (_index < _candidates.length - 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _index++);
          });
        }
        return _placeholder();
      },
    );
  }
}
