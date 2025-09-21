import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color colorFondo = Color.fromARGB(255, 255, 255, 255);
    const Color colorPrimario = Color.fromRGBO(0, 20, 34, 1);
    return Scaffold(
      backgroundColor: colorFondo,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ LOGO CON ESTILO CONSISTENTE (igual que registro de usuario)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 3,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Logo circular con borde elegante
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorPrimario.withOpacity(0.2),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorPrimario.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/LogoPinequitas.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Título de la app
                  Text(
                    'Pedidos1601',
                    style: TextStyle(
                      color: colorPrimario,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Subtítulo
                  Text(
                    'Sistema de gestión de pedidos',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimario,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Iniciar sesión',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Botón de Registro de Usuario
            SizedBox(
              width: 200,
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/registro');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorPrimario,
                  side: BorderSide(color: colorPrimario, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Registrarse',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/admin');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimario,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Vista Administrador'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 200,
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/empleado');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimario,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Vista Empleado'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 200,
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/repartidor');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimario,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Vista Repartidor'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 200,
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/cliente');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimario,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Vista Cliente'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 200,
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/restaurantes');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimario,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Vista Restaurantes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
