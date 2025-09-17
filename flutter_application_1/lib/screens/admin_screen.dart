import 'package:flutter/material.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administrador')),
      body: const Center(
        child: Text(
          'Estás en la vista de Administrador',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
