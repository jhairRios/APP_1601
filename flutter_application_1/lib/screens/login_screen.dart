import 'package:flutter/material.dart';
import '../widgets/flexible_image.dart';
import 'package:flutter/services.dart'; // ✅ Para copiar al portapapeles
import 'package:http/http.dart'
    as http; // ✅ Importamos http para hacer peticiones a la API
import 'dart:convert'; // ✅ Para convertir JSON
import '../services/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _rememberMe = false; // Guardar credenciales

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
    // Cargar credenciales guardadas (si existen)
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('saved_email') ?? '';
      final savedPassword = prefs.getString('saved_password') ?? '';
      if (savedEmail.isNotEmpty && savedPassword.isNotEmpty) {
        setState(() {
          _emailController.text = savedEmail;
          _passwordController.text = savedPassword;
          _rememberMe = true;
        });
      }
    } catch (_) {
      // No bloquear la pantalla si falla el acceso a SharedPreferences
    }
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

  /* // ✅ FUNCIÓN DE RECUPERACIÓN DE CONTRASEÑA - COMENTADA PARA EVITAR DUPLICACIÓN
  Future<void> _recuperarContrasena() async {
    final TextEditingController emailController = TextEditingController();
    bool isLoadingRecuperacion = false;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue[50]!,
                      Colors.white,
                      Colors.blue[50]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header con icono y título
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[600]!, Colors.blue[800]!],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.lock_reset_rounded,
                              size: 50,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Recuperar Contraseña',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 25),
                      
                      // Descripción
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.blue[100]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Colors.blue[700],
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Ingresa tu correo electrónico y te generaremos una nueva contraseña temporal.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue[800],
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 25),
                      
                      // Campo de email mejorado
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            labelText: 'Correo electrónico',
                            hintText: 'ejemplo@correo.com',
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.email_rounded,
                                color: Colors.blue[700],
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Botones mejorados
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: TextButton(
                                onPressed: () {
                                  emailController.dispose();
                                  Navigator.of(context).pop();
                                },
                                style: TextButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: Text(
                                  'Cancelar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 15),
                          
                          Expanded(
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.green[400]!, Colors.green[600]!],
                                ),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: isLoadingRecuperacion
                                    ? null
                                    : () async {
                                        final email = emailController.text.trim();
                                        if (email.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Por favor ingresa tu correo electrónico',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        setDialogState(() {
                                          isLoadingRecuperacion = true;
                                        });

                                        try {
                                          final response = await http.post(
                                            Uri.parse(
                                              API_BASE_URL,
                                            ),
                                            headers: {'Content-Type': 'application/json'},
                                            body: json.encode({
                                              'action': 'recover_password',
                                              'email': email,
                                            }),
                                          );

                                          if (response.statusCode == 200) {
                                            final data = json.decode(response.body);

                                            emailController.dispose();
                                            Navigator.of(context).pop();

                                            if (data['success'] == true) {
                                              // Mostrar contraseña en un modal cómodo para copiar
                                              _mostrarContrasenaModal(
                                                data['new_password'],
                                                email,
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    data['message'] ??
                                                        'Error al recuperar contraseña',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          } else {
                                            throw Exception('Error del servidor');
                                          }
                                        } catch (e) {
                                          emailController.dispose();
                                          Navigator.of(context).pop();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Error de conexión: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        } finally {
                                          setDialogState(() {
                                            isLoadingRecuperacion = false;
                                          });
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: isLoadingRecuperacion
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.send_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Enviar',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
  */ // FIN COMENTARIO

  // ✅ FUNCIÓN DE RECUPERACIÓN DE CONTRASEÑA - SIMPLIFICADA PARA EVITAR ERRORES
  void _recuperarContrasena() async {
    final TextEditingController emailController = TextEditingController();
    String? email;

    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Recuperar Contraseña'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ingresa tu correo electrónico:'),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(emailController.text.trim());
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );

    emailController.dispose();

    if (result != null && result.isNotEmpty) {
      email = result;

      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Procesando...'),
            ],
          ),
        ),
      );

      try {
        final response = await http.post(
          Uri.parse(API_BASE_URL),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'action': 'recover_password', 'email': email}),
        );

        Navigator.of(context).pop(); // Cerrar loading

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data['success'] == true) {
            // Mostrar contraseña en un modal cómodo para copiar
            _mostrarContrasenaModal(
              data['new_password'] ?? '',
              data['usuario'] ?? '',
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  data['message'] ?? 'Error al recuperar contraseña',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      } catch (e) {
        Navigator.of(context).pop(); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ✅ FUNCIÓN PARA MOSTRAR CONTRASEÑA EN MODAL CÓMODO
  void _mostrarContrasenaModal(String nuevaContrasena, String usuario) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              Icon(Icons.check_circle, size: 48, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                'Nueva Contraseña Generada',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Se generó una nueva contraseña temporal para:',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                usuario,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Tu nueva contraseña temporal es:',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        nuevaContrasena,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontFamily: 'monospace',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        // Copiar al portapapeles
                        try {
                          await Clipboard.setData(
                            ClipboardData(text: nuevaContrasena),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '✅ Contraseña copiada al portapapeles',
                                ),
                                duration: Duration(seconds: 2),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '❌ No se pudo copiar. Selecciona y copia manualmente.',
                                ),
                                duration: Duration(seconds: 3),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.copy),
                      tooltip: 'Copiar contraseña',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Anota o copia esta contraseña. Úsala para iniciar sesión.',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
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
        Uri.parse(API_BASE_URL),
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

        // Guardar user id / repartidor id en SharedPreferences para sesiones
        try {
          final prefs = await SharedPreferences.getInstance();
          final userId = data['user']['id']?.toString() ?? '';
          if (userId.isNotEmpty) {
            await prefs.setString('user_id', userId);
            if (userRole == 3) {
              // Si el usuario es repartidor, también guardar repartidor_id
              await prefs.setString('repartidor_id', userId);
            }
          }
          // Guardar o eliminar credenciales según checkbox "Recordarme"
          if (_rememberMe) {
            await prefs.setString('saved_email', _emailController.text.trim());
            await prefs.setString('saved_password', _passwordController.text);
          } else {
            await prefs.remove('saved_email');
            await prefs.remove('saved_password');
          }
        } catch (_) {
          // no bloquear el login si falla el guardado local
        }

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
                    // Logo: mostrar la imagen tal cual (sin recorte circular)
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: FlexibleImage(
                        source: 'assets/Pedidos.png',
                        fit: BoxFit.contain,
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
              // Recordarme (guardar credenciales)
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (bool? v) {
                      setState(() {
                        _rememberMe = v ?? false;
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                      child: const Text(
                        'Recordarme',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),

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
                  onPressed: _recuperarContrasena,
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
              const SizedBox(height: 32),

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
