import 'package:flutter/material.dart';

class Restaurante {
  final String nombre;
  final String imagen;
  final String descripcion;

  Restaurante({
    required this.nombre,
    required this.imagen,
    required this.descripcion,
  });
}

final List<Restaurante> restaurantesEjemplo = [
  Restaurante(
    nombre: 'Pizza Express',
    imagen: 'https://images.unsplash.com/photo-1513104890138-7c749659a591',
    descripcion: 'Las mejores pizzas artesanales.',
  ),
  Restaurante(
    nombre: 'Sushi House',
    imagen: 'https://images.unsplash.com/photo-1543353071-873f17a7a088',
    descripcion: 'Sushi fresco y delicioso.',
  ),
  Restaurante(
    nombre: 'Burger Town',
    imagen: 'https://images.unsplash.com/photo-1550547660-d9450f859349',
    descripcion: 'Hamburguesas premium.',
  ),
];

class RestaurantesScreen extends StatelessWidget {
  const RestaurantesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restaurantes')),
      body: ListView.builder(
        itemCount: restaurantesEjemplo.length,
        itemBuilder: (context, index) {
          final restaurante = restaurantesEjemplo[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Image.network(
                restaurante.imagen,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
              title: Text(restaurante.nombre),
              subtitle: Text(restaurante.descripcion),
            ),
          );
        },
      ),
    );
  }
}
