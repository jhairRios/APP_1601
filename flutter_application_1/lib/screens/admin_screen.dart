import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  // Paleta de colores
  final Color colorFondo = const Color(0xFF1D2828);
  final Color colorPrimario = const Color(0xFFF4AC1E);
  final Color colorSecundario = const Color(0xFF12C0E1);
  final Color colorAcento = const Color(0xFFF3343C);
  final Color colorAmarilloClaro = const Color(0xFFF3EC18);

  final TextEditingController _nombreController = TextEditingController();
  File? _logoFile;
  String? _categoriaSeleccionada;
  final List<String> _categorias = [
    'Comida rápida',
    'Sushi',
    'Pizzería',
    'Cafetería',
    'Otros',
  ];
  final List<Map<String, dynamic>> _empresas = [];

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _logoFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFondo,
      appBar: AppBar(
        title: const Text('Administrador'),
        backgroundColor: colorPrimario,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Agregar empresa',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nombreController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Nombre de la empresa',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: colorFondo.withOpacity(0.7),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorSecundario, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorAcento, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _pickLogo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorSecundario,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Seleccionar logo'),
                  ),
                  const SizedBox(width: 16),
                  _logoFile != null
                      ? Image.file(
                          _logoFile!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : Text(
                          'Sin logo',
                          style: TextStyle(color: Colors.white70),
                        ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _categoriaSeleccionada,
                dropdownColor: colorFondo,
                items: _categorias
                    .map(
                      (cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(
                          cat,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _categoriaSeleccionada = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Categoría',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: colorFondo.withOpacity(0.7),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorSecundario, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorAcento, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_nombreController.text.isNotEmpty &&
                      _categoriaSeleccionada != null) {
                    setState(() {
                      _empresas.add({
                        'nombre': _nombreController.text,
                        'logo': _logoFile,
                        'categoria': _categoriaSeleccionada,
                      });
                      _nombreController.clear();
                      _logoFile = null;
                      _categoriaSeleccionada = null;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimario,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Agregar empresa'),
              ),
              const SizedBox(height: 32),
              const Text(
                'Empresas registradas:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ..._empresas.map(
                (empresa) => Card(
                  color: Colors.white,
                  child: ListTile(
                    leading: empresa['logo'] != null
                        ? Image.file(
                            empresa['logo'],
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          )
                        : null,
                    title: Text(
                      empresa['nombre'] ?? '',
                      style: const TextStyle(color: Colors.black),
                    ),
                    subtitle: Text(
                      'Categoría: ${empresa['categoria'] ?? ''}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
