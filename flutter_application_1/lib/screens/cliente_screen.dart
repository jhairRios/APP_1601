import 'package:flutter/material.dart';

class ClienteScreen extends StatelessWidget {
  const ClienteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cliente')),
      body: const Center(
        child: Text(
          'Estás en la vista de Cliente',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
