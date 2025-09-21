import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/RegistroUsuario.dart';
import 'screens/admin_screen.dart';
import 'screens/empleado_screen.dart';
import 'screens/repartidor_screen.dart';
import 'screens/cliente_screen.dart';
import 'screens/empresa_screen.dart';
import 'screens/usuario_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 255, 255, 255),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/registro': (context) => const RegistroUsuarioScreen(),
        '/admin': (context) => const AdminScreen(),
        '/empleado': (context) => const EmpleadoScreen(),
        '/repartidor': (context) => const RepartidorScreen(),
        '/cliente': (context) => const ClienteScreen(),
        '/empresa': (context) => const EmpresaScreen(),
        '/usuario': (context) => const UsuarioScreen(),
        '/menu': (context) => const MenuScreen(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
