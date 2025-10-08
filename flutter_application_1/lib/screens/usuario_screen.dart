import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_config.dart';

class UsuarioScreen extends StatefulWidget {
  const UsuarioScreen({super.key});

  @override
  State<UsuarioScreen> createState() => _UsuarioScreenState();
}

class _UsuarioScreenState extends State<UsuarioScreen> {
  final Color colorTexto = const Color.fromARGB(255, 0, 0, 0);
  final Color colorFondo = const Color.fromARGB(255, 255, 255, 255);
  final Color colorPrimario = const Color.fromRGBO(0, 20, 34, 1);

  // Controllers para el formulario
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();

  // Controllers para edición
  final TextEditingController _editNombreController = TextEditingController();
  final TextEditingController _editCorreoController = TextEditingController();
  final TextEditingController _editTelefonoController = TextEditingController();
  final TextEditingController _editPasswordController = TextEditingController();

  // Variables de estado
  List<Map<String, dynamic>> _usuarios = [];
  List<Map<String, dynamic>> _roles = [];
  bool _cargando = true;
  String? _rolSeleccionado;
  String? _editRolSeleccionado;
  bool _editActivo = true;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _contrasenaController.dispose();
    _editNombreController.dispose();
    _editCorreoController.dispose();
    _editTelefonoController.dispose();
    _editPasswordController.dispose();
    super.dispose();
  }

  // Inicializar datos
  Future<void> _inicializar() async {
    await _cargarRoles();
    await _cargarUsuarios();
    setState(() {
      _cargando = false;
    });
  }

  // Cargar roles desde BD
  Future<void> _cargarRoles() async {
    try {
        final response = await http.get(
          Uri.parse('$API_BASE_URL?action=get_roles'),
        );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _roles = List<Map<String, dynamic>>.from(data['roles']);
          });
        }
      }
    } catch (e) {
      print('Error cargando roles: $e');
    }
  }

  // Cargar usuarios desde BD
  Future<void> _cargarUsuarios() async {
    try {
        final response = await http.get(
          Uri.parse('$API_BASE_URL?action=get_users'),
        );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _usuarios = List<Map<String, dynamic>>.from(data['users']);
          });
        }
      }
    } catch (e) {
      print('Error cargando usuarios: $e');
    }
  }

  // Crear nuevo usuario
  Future<void> _crearUsuario() async {
    if (_nombreController.text.isEmpty ||
        _correoController.text.isEmpty ||
        _telefonoController.text.isEmpty ||
        _contrasenaController.text.isEmpty ||
        _rolSeleccionado == null) {
      _mostrarMensaje('Por favor completa todos los campos', esError: true);
      return;
    }

    try {
        final response = await http.post(
          Uri.parse(API_BASE_URL),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'create_user',
          'nombre': _nombreController.text,
          'correo': _correoController.text,
          'telefono': _telefonoController.text,
          'contrasena': _contrasenaController.text,
          'id_rol': _rolSeleccionado,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _mostrarMensaje('Usuario creado exitosamente');
          _limpiarFormulario();
          await _cargarUsuarios(); // Recargar la lista
        } else {
          _mostrarMensaje(
            data['message'] ?? 'Error creando usuario',
            esError: true,
          );
        }
      }
    } catch (e) {
      _mostrarMensaje('Error de conexión: $e', esError: true);
    }
  }

  // Limpiar formulario
  void _limpiarFormulario() {
    _nombreController.clear();
    _correoController.clear();
    _telefonoController.clear();
    _contrasenaController.clear();
    setState(() {
      _rolSeleccionado = null;
    });
  }

  // Mostrar mensaje
  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Mostrar modal de edición de usuario
  void _mostrarModalEdicion(Map<String, dynamic> usuario) {
    // Llenar los campos con los datos actuales del usuario
    _editNombreController.text = usuario['Nombre'] ?? '';
    _editCorreoController.text = usuario['Correo'] ?? '';
    _editTelefonoController.text = usuario['Telefono'] ?? '';
    _editPasswordController.clear();
    _editRolSeleccionado = usuario['Id_Rol']?.toString();
    _editActivo = (usuario['activo'] ?? 1) == 1;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: EdgeInsets.zero,
              contentPadding: const EdgeInsets.all(24),
              title: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorPrimario,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Editar: ${usuario['Nombre'] ?? 'Usuario'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Campos del formulario en forma más compacta
                      Row(
                        children: [
                          Expanded(
                            child: _buildCompactField(
                              controller: _editNombreController,
                              label: 'Nombre',
                              icon: Icons.person_outline,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildCompactField(
                              controller: _editCorreoController,
                              label: 'Email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildCompactField(
                              controller: _editTelefonoController,
                              label: 'Teléfono',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildCompactField(
                              controller: _editPasswordController,
                              label: 'Nueva contraseña',
                              icon: Icons.lock_outline,
                              obscureText: true,
                              isOptional: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Selector de Rol
                      DropdownButtonFormField<String>(
                        value: _editRolSeleccionado,
                        decoration: InputDecoration(
                          labelText: 'Rol',
                          prefixIcon: Icon(
                            Icons.admin_panel_settings_outlined,
                            color: colorPrimario,
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        items: _roles.map<DropdownMenuItem<String>>((rol) {
                          return DropdownMenuItem<String>(
                            value: rol['Id_Rol'].toString(),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _getColorRol(rol['Descripcion']),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  rol['Descripcion'] ?? 'Sin nombre',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _editRolSeleccionado = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Estado activo/inactivo más compacto
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _editActivo ? Icons.account_circle : Icons.block,
                              color: _editActivo ? Colors.green : Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Estado de la cuenta',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Text(
                              _editActivo ? 'Activo' : 'Inactivo',
                              style: TextStyle(
                                fontSize: 12,
                                color: _editActivo ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: _editActivo,
                              onChanged: (bool value) {
                                setState(() {
                                  _editActivo = value;
                                });
                              },
                              activeColor: colorPrimario,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _actualizarUsuario(usuario['Id_Usuario']);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorPrimario,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.save, size: 16),
                  label: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Widget helper para campos compactos
  Widget _buildCompactField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool isOptional = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: isOptional ? '$label (Opcional)' : label,
        labelStyle: TextStyle(fontSize: 12, color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: colorPrimario, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }

  // Actualizar usuario
  Future<void> _actualizarUsuario(int idUsuario) async {
    if (_editNombreController.text.isEmpty ||
        _editCorreoController.text.isEmpty ||
        _editRolSeleccionado == null) {
      _mostrarMensaje(
        'Por favor completa los campos obligatorios',
        esError: true,
      );
      return;
    }

    try {
      final Map<String, dynamic> requestBody = {
        'action': 'update_user',
        'id_usuario': idUsuario,
        'nombre': _editNombreController.text,
        'correo': _editCorreoController.text,
        'telefono': _editTelefonoController.text,
        'id_rol': int.parse(_editRolSeleccionado!),
        'activo': _editActivo ? 1 : 0,
      };

      // Solo enviar contraseña si se ingresó una nueva
      if (_editPasswordController.text.isNotEmpty) {
        requestBody['password'] = _editPasswordController.text;
      }

        final response = await http.post(
          Uri.parse(API_BASE_URL),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _mostrarMensaje('Usuario actualizado exitosamente');
          await _cargarUsuarios(); // Recargar la lista
        } else {
          _mostrarMensaje(
            data['message'] ?? 'Error actualizando usuario',
            esError: true,
          );
        }
      }
    } catch (e) {
      _mostrarMensaje('Error de conexión: $e', esError: true);
    }
  }

  // Cambiar estado de usuario (activar/desactivar)
  Future<void> _cambiarEstadoUsuario(Map<String, dynamic> usuario) async {
    int nuevoEstado = usuario['activo'] == 1 ? 0 : 1;

    try {
      final response = await http.post(
          Uri.parse(API_BASE_URL),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'toggle_user_status',
          'id_usuario': usuario['Id_Usuario'],
          'activo': nuevoEstado,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _mostrarMensaje(data['message']);
          await _cargarUsuarios(); // Recargar la lista
        } else {
          _mostrarMensaje(
            data['message'] ?? 'Error cambiando estado',
            esError: true,
          );
        }
      }
    } catch (e) {
      _mostrarMensaje('Error de conexión: $e', esError: true);
    }
  }

  // Eliminar usuario definitivamente
  Future<void> _eliminarUsuarioDefinitivamente(int idUsuario) async {
    try {
      final response = await http.post(
          Uri.parse(API_BASE_URL),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'delete_user_permanently',
          'id_usuario': idUsuario,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _mostrarMensaje('Usuario eliminado permanentemente');
          await _cargarUsuarios(); // Recargar la lista
        } else {
          _mostrarMensaje(
            data['message'] ?? 'Error eliminando usuario',
            esError: true,
          );
        }
      }
    } catch (e) {
      _mostrarMensaje('Error de conexión: $e', esError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFondo,
      appBar: AppBar(
        title: const Text(
          'Gestión de Usuarios',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorPrimario,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título de la sección
                  Text(
                    'Crear Nuevo Usuario',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorPrimario,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Formulario de creación
                  Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorPrimario.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Campo Nombre
                        TextFormField(
                          controller: _nombreController,
                          decoration: InputDecoration(
                            labelText: 'Nombre completo',
                            labelStyle: TextStyle(color: colorTexto),
                            hintText: 'Ingresa el nombre completo',
                            hintStyle: TextStyle(
                              color: colorTexto.withOpacity(0.6),
                            ),
                            prefixIcon: Icon(
                              Icons.person,
                              color: colorPrimario,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colorPrimario),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorPrimario,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Campo Email
                        TextFormField(
                          controller: _correoController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Correo electrónico',
                            labelStyle: TextStyle(color: colorTexto),
                            hintText: 'ejemplo@correo.com',
                            hintStyle: TextStyle(
                              color: colorTexto.withOpacity(0.6),
                            ),
                            prefixIcon: Icon(Icons.email, color: colorPrimario),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colorPrimario),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorPrimario,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Campo Teléfono
                        TextFormField(
                          controller: _telefonoController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Teléfono',
                            labelStyle: TextStyle(color: colorTexto),
                            hintText: '+51 999 999 999',
                            hintStyle: TextStyle(
                              color: colorTexto.withOpacity(0.6),
                            ),
                            prefixIcon: Icon(Icons.phone, color: colorPrimario),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colorPrimario),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorPrimario,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Campo Contraseña
                        TextFormField(
                          controller: _contrasenaController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            labelStyle: TextStyle(color: colorTexto),
                            hintText: 'Mínimo 6 caracteres',
                            hintStyle: TextStyle(
                              color: colorTexto.withOpacity(0.6),
                            ),
                            prefixIcon: Icon(Icons.lock, color: colorPrimario),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colorPrimario),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorPrimario,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Dropdown de roles
                        DropdownButtonFormField<String>(
                          value: _rolSeleccionado,
                          decoration: InputDecoration(
                            labelText: 'Rol',
                            labelStyle: TextStyle(color: colorTexto),
                            prefixIcon: Icon(
                              Icons.admin_panel_settings,
                              color: colorPrimario,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colorPrimario),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorPrimario,
                                width: 2,
                              ),
                            ),
                          ),
                          items: _roles.map((rol) {
                            return DropdownMenuItem<String>(
                              value: rol['Id_Rol'].toString(),
                              child: Text(rol['Descripcion']),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _rolSeleccionado = newValue;
                            });
                          },
                          hint: const Text('Selecciona un rol'),
                        ),
                        const SizedBox(height: 24),

                        // Botón crear usuario
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _crearUsuario,
                            icon: const Icon(
                              Icons.person_add,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Crear Usuario',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorPrimario,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Título de lista de usuarios
                  Row(
                    children: [
                      Text(
                        'Usuarios Registrados',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorPrimario,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_usuarios.length} usuarios',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorTexto.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Lista de usuarios
                  _usuarios.isEmpty
                      ? Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: colorPrimario.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay usuarios registrados',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: colorPrimario.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _usuarios.length,
                          itemBuilder: (context, index) {
                            final usuario = _usuarios[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: Colors.white,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Header con nombre y rol
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                usuario['Nombre'] ??
                                                    'Sin nombre',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: colorTexto,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _getColorRol(
                                                  usuario['Descripcion'],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                usuario['Descripcion'] ??
                                                    'Sin rol',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),

                                        // Información del usuario
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.email,
                                              size: 16,
                                              color: colorPrimario,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                usuario['Correo'] ??
                                                    'Sin email',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: colorTexto.withOpacity(
                                                    0.8,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),

                                        Row(
                                          children: [
                                            Icon(
                                              Icons.phone,
                                              size: 16,
                                              color: colorPrimario,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              usuario['Telefono'] ??
                                                  'Sin teléfono',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: colorTexto.withOpacity(
                                                  0.8,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),

                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 16,
                                              color: colorPrimario,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Registrado: ${usuario['Fecha_Registro'] ?? 'Fecha desconocida'}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: colorTexto.withOpacity(
                                                  0.6,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),

                                        // Estado del usuario
                                        Row(
                                          children: [
                                            Icon(
                                              usuario['activo'] == 1
                                                  ? Icons.check_circle
                                                  : Icons.cancel,
                                              size: 16,
                                              color: usuario['activo'] == 1
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              usuario['activo'] == 1
                                                  ? 'Activo'
                                                  : 'Inactivo',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: usuario['activo'] == 1
                                                    ? Colors.green
                                                    : Colors.red,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),

                                        // Botones de acción
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            // Botón Editar
                                            OutlinedButton.icon(
                                              onPressed: () {
                                                _mostrarModalEdicion(usuario);
                                              },
                                              icon: Icon(
                                                Icons.edit,
                                                size: 16,
                                                color: colorPrimario,
                                              ),
                                              label: Text(
                                                'Editar',
                                                style: TextStyle(
                                                  color: colorPrimario,
                                                ),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                side: BorderSide(
                                                  color: colorPrimario,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                              ),
                                            ),
                                            // Botón Activar/Desactivar
                                            OutlinedButton.icon(
                                              onPressed: () =>
                                                  _cambiarEstadoUsuario(
                                                    usuario,
                                                  ),
                                              icon: Icon(
                                                usuario['activo'] == 1
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                                size: 16,
                                                color: usuario['activo'] == 1
                                                    ? Colors.orange
                                                    : Colors.green,
                                              ),
                                              label: Text(
                                                usuario['activo'] == 1
                                                    ? 'Desactivar'
                                                    : 'Activar',
                                                style: TextStyle(
                                                  color: usuario['activo'] == 1
                                                      ? Colors.orange
                                                      : Colors.green,
                                                ),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                side: BorderSide(
                                                  color: usuario['activo'] == 1
                                                      ? Colors.orange
                                                      : Colors.green,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                              ),
                                            ),
                                            // Botón Eliminar Definitivamente
                                            OutlinedButton.icon(
                                              onPressed: () =>
                                                  _eliminarUsuarioDefinitivamente(
                                                    usuario['Id_Usuario'],
                                                  ),
                                              icon: const Icon(
                                                Icons.delete_forever,
                                                size: 16,
                                                color: Colors.red,
                                              ),
                                              label: const Text(
                                                'Eliminar',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(
                                                  color: Colors.red,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }

  // Obtener color según el rol
  Color _getColorRol(String? rol) {
    switch (rol?.toLowerCase()) {
      case 'administrador':
        return Colors.red;
      case 'usuario':
        return Colors.blue;
      case 'repartidor':
        return Colors.orange;
      case 'empleado':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
