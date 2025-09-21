import 'package:flutter/material.dart';
import 'package:http/http.dart'
    as http; // ✅ Importamos http para hacer peticiones a la API
import 'dart:convert'; // ✅ Para convertir JSON

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ✅ CONTROLADORES para capturar texto de los campos
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // ✅ ESTADOS para el foco de los campos (igual que antes)
  final FocusNode _userFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _userFocused = false;
  bool _passwordFocused = false;

  // ✅ NUEVOS ESTADOS para el login
  bool _isLoading = false; // Para mostrar el indicador de carga
  String _errorMessage = ''; // Para mostrar errores

  @override
  void initState() {
    super.initState();
    _userFocusNode.addListener(() {
      setState(() {
        _userFocused = _userFocusNode.hasFocus;
      });
    });
    _passwordFocusNode.addListener(() {
      setState(() {
        _passwordFocused = _passwordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    // ✅ LIMPIEZA: Liberar memoria de los controladores y focus nodes
    _emailController.dispose();
    _passwordController.dispose();
    _userFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // ✅ FUNCIÓN DE LOGIN: Envía credenciales a la API PHP
  Future<void> _login() async {
    // Limpiar mensajes de error previos
    setState(() {
      _errorMessage = '';
      _isLoading = true; // Mostrar indicador de carga
    });

    try {
      // ✅ PETICIÓN HTTP: Enviamos email y password a la API
      final response = await http.post(
        Uri.parse(
          'http://localhost/APP_1601/flutter_application_1/php/api.php', //Ruta Diany Enamorado
        ),
        body: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        },
      );

      // ✅ PROCESAR RESPUESTA: Convertir JSON de respuesta
      final data = json.decode(response.body);

      if (data['success']) {
        // ✅ LOGIN EXITOSO: Obtener el rol del usuario
        final userRole = data['user']['role_id'];
        final userName = data['user']['name'];

        // ✅ REDIRECCIÓN SEGÚN ROL: Navegar a la pantalla correspondiente
        String routeDestination;
        switch (userRole) {
          case 1:
            routeDestination = '/admin'; // 👑 Administrador
            break;
          case 2:
            routeDestination = '/usuario'; // 👨‍💼 Empleado
            break;
          case 3:
            routeDestination = '/repartidor'; // 🚗 Repartidor
            break;
          case 4:
            routeDestination = '/empleado'; // 👤 Cliente
            break;
          default:
            routeDestination = '/usuario'; // 🔧 Rol desconocido
        }

        String Descripcion;
        switch (userRole) {
          case 1:
            Descripcion = 'Administrador';
            break;
          case 2:
            Descripcion = 'Usuario';
            break;
          case 3:
            Descripcion = 'Repartidor';
            break;
          case 4:
            Descripcion = 'Empleado';
            break;
          default:
            Descripcion = 'Usuario';
        }

        // ✅ NAVEGAR: Ir a la pantalla correspondiente y limpiar el stack
        Navigator.pushReplacementNamed(context, routeDestination);

        // ✅ OPCIONAL: Mostrar mensaje de bienvenida
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Bienvenido, $userName! Rol: $Descripcion'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // ✅ LOGIN FALLÓ: Mostrar mensaje de error
        setState(() {
          _errorMessage = data['message'] ?? 'Credenciales incorrectas';
        });
      }
    } catch (e) {
      // ✅ ERROR DE CONEXIÓN: Mostrar error de red
      setState(() {
        _errorMessage = 'Error de conexión: ${e.toString()}';
      });
    } finally {
      // ✅ FINALIZAR: Ocultar indicador de carga
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Colores de la paleta
    const Color colorTexto = Color.fromARGB(255, 0, 0, 0);
    const Color colorFondo = Color.fromARGB(255, 255, 255, 255);
    const Color colorPrimario = Color.fromRGBO(0, 20, 34, 1);

    return Scaffold(
      backgroundColor: colorFondo,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: AssetImage('assets/LogoPinequitas.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Título
              Text(
                'Bienvenido',
                style: TextStyle(
                  color: colorPrimario,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Inicia sesión para continuar',
                style: TextStyle(color: colorPrimario, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Campo de email (antes era "usuario")
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _userFocused
                      ? [
                          BoxShadow(
                            color: colorPrimario.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 0),
                          ),
                        ]
                      : [],
                ),
                child: TextField(
                  controller: _emailController, // ✅ CONECTAR controlador
                  focusNode: _userFocusNode,
                  keyboardType:
                      TextInputType.emailAddress, // ✅ Teclado para email
                  style: const TextStyle(color: colorTexto),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Email', // ✅ CAMBIAR de "Usuario" a "Email"
                    hintStyle: const TextStyle(color: colorTexto),
                    prefixIcon: Icon(
                      Icons.email,
                      color: colorPrimario,
                    ), // ✅ CAMBIAR icono
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
              ),
              const SizedBox(height: 20),
              // Campo contraseña
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _passwordFocused
                      ? [
                          BoxShadow(
                            color: colorPrimario.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 0),
                          ),
                        ]
                      : [],
                ),
                child: TextField(
                  controller: _passwordController, // ✅ CONECTAR controlador
                  focusNode: _passwordFocusNode,
                  style: const TextStyle(color: colorTexto),
                  obscureText: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Contraseña',
                    hintStyle: const TextStyle(color: colorTexto),
                    prefixIcon: Icon(Icons.lock, color: colorPrimario),
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
              ),
              const SizedBox(height: 12),

              // ✅ MENSAJE DE ERROR: Mostrar errores de login
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ¿Olvidaste tu contraseña?
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      color: colorPrimario,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Botón de login
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : _login, // ✅ CONECTAR función de login
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorPrimario,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child:
                      _isLoading // ✅ MOSTRAR loading o texto
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Iniciar sesión',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              // Botón de cancelar
              SizedBox(
                height: 45,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorPrimario,
                    side: BorderSide(color: colorPrimario, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Pie de página opcional
              Text(
                '© 2025 Pedidos1601',
                style: TextStyle(color: Colors.white24, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
