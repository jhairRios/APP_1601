import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  // Colores de la paleta
  final Color colorTexto = const Color.fromARGB(255, 0, 0, 0);
  final Color colorFondo = const Color.fromARGB(255, 255, 255, 255);
  final Color colorPrimario = const Color.fromRGBO(0, 20, 34, 1);

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
              Text(
                'Agregar empresa',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorPrimario,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nombreController,
                style: TextStyle(color: colorTexto),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Nombre de la empresa',
                  hintStyle: TextStyle(color: colorTexto),
                  prefixIcon: Icon(Icons.business, color: colorPrimario),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorPrimario, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorPrimario, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _pickLogo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorPrimario,
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
                      : Text('Sin logo', style: TextStyle(color: colorTexto)),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _categoriaSeleccionada,
                dropdownColor: Colors.white,
                items: _categorias
                    .map(
                      (cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat, style: TextStyle(color: colorTexto)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _categoriaSeleccionada = value;
                  });
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Categoría',
                  hintStyle: TextStyle(color: colorTexto),
                  prefixIcon: Icon(Icons.category, color: colorPrimario),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorPrimario, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: colorPrimario, width: 2),
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
              Text(
                'Empresas registradas:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorPrimario,
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
