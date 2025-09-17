import 'package:flutter/material.dart';

class RepartidorScreen extends StatelessWidget {
  const RepartidorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Repartidor')),
      body: const Center(
        child: Text(
          'Estás en la vista de Repartidor',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
