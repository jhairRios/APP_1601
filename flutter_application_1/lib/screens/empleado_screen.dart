import 'package:flutter/material.dart';

class EmpleadoScreen extends StatelessWidget {
  const EmpleadoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Empleado')),
      body: const Center(
        child: Text(
          'Estás en la vista de Empleado',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
