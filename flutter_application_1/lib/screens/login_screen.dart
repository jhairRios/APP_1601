import 'package:flutter/material.dart';
import 'package:http/http.dart'
    as http; // ✅ Importamos http para hacer peticiones a la API
import 'dart:convert'; // ✅ Para convertir JSON
import '../services/auth_service.dart'; // ✅ NUEVO: Importar servicio de Google

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
  bool _isGoogleLoading = false; // Para el loading del botón de Google

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

  // ✅ FUNCIÓN REUTILIZABLE: Redirección por roles
  void _redirectByRole(int userRole, String userName) {
    String routeDestination;
    String descripcion;
    
    switch (userRole) {
      case 1:
        routeDestination = '/admin';
        descripcion = 'Administrador';
        break;
      case 2:
        routeDestination = '/cliente';
        descripcion = 'Usuario';
        break;
      case 3:
        routeDestination = '/repartidor';
        descripcion = 'Repartidor';
        break;
      case 4:
        routeDestination = '/empleado';
        descripcion = 'Empleado';
        break;
      default:
        routeDestination = '/cliente';
        descripcion = 'Cliente';
    }

    // Navegar a la pantalla correspondiente
    Navigator.pushReplacementNamed(context, routeDestination);

    // Mostrar mensaje de bienvenida
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Bienvenido, $userName! Rol: $descripcion'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
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
          //'http://localhost/APP_1601/flutter_application_1/php/api.php' //Ruta Diany Enamorado
          //'http://localhost/Aplicacion_1/APP1601/APP_1601/flutter_application_1/php/api.php' //Ruta Angel Perez
          //'http://localhost/Proyecto_APP/Proyecto_APP/flutter_application_1/php/api.php', //Ruta Jhair Rios
          'http://localhost/Proyecto_APP/Proyecto_APP/flutter_application_1/php/api.php' //Ruta Derick Dair
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

        // ✅ REDIRECCIÓN: Usar función reutilizable
        _redirectByRole(userRole, userName);
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

  // ✅ NUEVA FUNCIÓN: Login con Google
  Future<void> _googleLogin() async {
    setState(() {
      _errorMessage = '';
      _isGoogleLoading = true;
    });

    try {
      final result = await AuthService.signInWithGoogle();
      
      if (result['success']) {
        // Login exitoso
        final userRole = result['user']['role_id'];
        final userName = result['user']['name'];

        // ✅ REDIRECCIÓN: Usar función reutilizable
        _redirectByRole(userRole, userName);
      } else {
        // Login falló
        setState(() {
          _errorMessage = result['message'] ?? 'Error en el login con Google';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error con Google Sign-In: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isGoogleLoading = false;
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
              // ✅ ENCABEZADO CON LOGO (igual que registro de usuario)
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

                    // Título principal
                    Text(
                      'Bienvenido',
                      style: TextStyle(
                        color: colorPrimario,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Subtítulo
                    Text(
                      'Inicia sesión para continuar',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
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
              
              // ✅ NUEVO: Separador "O"
              Row(
                children: [
                  Expanded(child: Divider(color: colorPrimario.withOpacity(0.3))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'O',
                      style: TextStyle(
                        color: colorPrimario,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: colorPrimario.withOpacity(0.3))),
                ],
              ),
              const SizedBox(height: 16),
              
              // ✅ NUEVO: Botón de Google Sign-In
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _isGoogleLoading ? null : _googleLogin,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorPrimario,
                    side: BorderSide(color: colorPrimario, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isGoogleLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(Icons.login, size: 20),
                  label: Text(
                    _isGoogleLoading 
                        ? 'Conectando...' 
                        : 'Continuar con Google',
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // ✅ NUEVO: Enlace a registro
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/registro');
                },
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 14),
                    children: [
                      TextSpan(
                        text: '¿No tienes cuenta? ',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      TextSpan(
                        text: 'Regístrate',
                        style: TextStyle(
                          color: colorPrimario,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
