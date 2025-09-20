import 'package:flutter/material.dart';

class UsuarioScreen extends StatefulWidget {
  const UsuarioScreen({super.key});

  @override
  State<UsuarioScreen> createState() => _UsuarioScreenState();
}

class _UsuarioScreenState extends State<UsuarioScreen> {
  // Colores de la paleta
  final Color colorTexto = const Color.fromARGB(255, 0, 0, 0);
  final Color colorFondo = const Color.fromARGB(255, 255, 255, 255);
  final Color colorPrimario = const Color.fromRGBO(0, 20, 34, 1);

  // Lista de usuarios registrados
  final List<Map<String, dynamic>> _usuarios = [
    {
      'nombre': 'Jhair Rios',
      'correo': 'jhair.rios@example.com',
      'telefono': '123456789',
      'rol': 'Administrador',
      'fechaRegistro': '2024-01-15',
    },
    {
      'nombre': 'Diany Enamorado',
      'correo': 'diany.enamorado@example.com',
      'telefono': '987654321',
      'rol': 'Empleado',
      'fechaRegistro': '2024-01-20',
    },
    {
      'nombre': 'Angel Perez',
      'correo': 'angel.perez@example.com',
      'telefono': '456789123',
      'rol': 'Repartidor',
      'fechaRegistro': '2024-01-25',
    },
  ];

  // Variables para el formulario
  String? _rolSeleccionado;
  final List<String> _roles = ['Administrador', 'Empleado', 'Repartidor'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFondo,
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: colorPrimario,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título
            Text(
              'Administrar Usuarios del Sistema',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorPrimario,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Botón para agregar usuario
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colorPrimario.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  _mostrarFormularioUsuario(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimario,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text(
                      'Agregar Nuevo Usuario',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Título de los usuarios
            Text(
              'Usuarios Registrados',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorPrimario,
              ),
            ),
            const SizedBox(height: 12),

            // Lista de usuarios en cards
            Expanded(
              child: ListView.builder(
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
                          boxShadow: [
                            BoxShadow(
                              color: colorPrimario.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header con nombre y rol
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      usuario['nombre'] ?? '',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: colorTexto,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getColorRol(usuario['rol']),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      usuario['rol'] ?? '',
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
                                      usuario['correo'] ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: colorTexto.withOpacity(0.8),
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
                                    usuario['telefono'] ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colorTexto.withOpacity(0.8),
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
                                    'Registrado: ${usuario['fechaRegistro'] ?? ''}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colorTexto.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Botones de acción
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      // TODO: Implementar edición de usuario
                                    },
                                    icon: Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: colorPrimario,
                                    ),
                                    label: Text(
                                      'Editar',
                                      style: TextStyle(color: colorPrimario),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: colorPrimario),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      // TODO: Implementar eliminación de usuario
                                    },
                                    icon: const Icon(
                                      Icons.delete,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                    label: const Text(
                                      'Eliminar',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.red),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
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
            ),
          ],
        ),
      ),
    );
  }

  // Función para obtener color según el rol
  Color _getColorRol(String? rol) {
    switch (rol) {
      case 'Administrador':
        return Colors.red.shade600;
      case 'Empleado':
        return Colors.blue.shade600;
      case 'Repartidor':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  // Modal para agregar/editar usuario
  void _mostrarFormularioUsuario(BuildContext context) {
    final TextEditingController nombreController = TextEditingController();
    final TextEditingController correoController = TextEditingController();
    final TextEditingController telefonoController = TextEditingController();
    final TextEditingController contrasenaController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Agregar Nuevo Usuario',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorPrimario,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Campo Nombre
                      TextField(
                        controller: nombreController,
                        style: TextStyle(color: colorTexto),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          hintText: 'Nombre completo',
                          hintStyle: TextStyle(
                            color: colorTexto.withOpacity(0.6),
                          ),
                          prefixIcon: Icon(Icons.person, color: colorPrimario),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorPrimario,
                              width: 1,
                            ),
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

                      // Campo Correo
                      TextField(
                        controller: correoController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: colorTexto),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          hintText: 'Correo electrónico',
                          hintStyle: TextStyle(
                            color: colorTexto.withOpacity(0.6),
                          ),
                          prefixIcon: Icon(Icons.email, color: colorPrimario),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorPrimario,
                              width: 1,
                            ),
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
                      TextField(
                        controller: telefonoController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: colorTexto),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          hintText: 'Teléfono',
                          hintStyle: TextStyle(
                            color: colorTexto.withOpacity(0.6),
                          ),
                          prefixIcon: Icon(Icons.phone, color: colorPrimario),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorPrimario,
                              width: 1,
                            ),
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
                      TextField(
                        controller: contrasenaController,
                        obscureText: true,
                        style: TextStyle(color: colorTexto),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          hintText: 'Contraseña',
                          hintStyle: TextStyle(
                            color: colorTexto.withOpacity(0.6),
                          ),
                          prefixIcon: Icon(Icons.lock, color: colorPrimario),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorPrimario,
                              width: 1,
                            ),
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

                      // Dropdown Rol
                      DropdownButtonFormField<String>(
                        value: _rolSeleccionado,
                        dropdownColor: Colors.white,
                        items: _roles
                            .map(
                              (rol) => DropdownMenuItem(
                                value: rol,
                                child: Text(
                                  rol,
                                  style: TextStyle(color: colorTexto),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setStateDialog(() {
                            _rolSeleccionado = value;
                          });
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          hintText: 'Seleccionar rol',
                          hintStyle: TextStyle(
                            color: colorTexto.withOpacity(0.6),
                          ),
                          prefixIcon: Icon(
                            Icons.admin_panel_settings,
                            color: colorPrimario,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorPrimario,
                              width: 1,
                            ),
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
                      const SizedBox(height: 24),

                      // Botones
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _rolSeleccionado = null;
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colorPrimario,
                                side: BorderSide(color: colorPrimario),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (nombreController.text.isNotEmpty &&
                                    correoController.text.isNotEmpty &&
                                    telefonoController.text.isNotEmpty &&
                                    contrasenaController.text.isNotEmpty &&
                                    _rolSeleccionado != null) {
                                  // Agregar usuario a la lista
                                  setState(() {
                                    _usuarios.add({
                                      'nombre': nombreController.text,
                                      'correo': correoController.text,
                                      'telefono': telefonoController.text,
                                      'rol': _rolSeleccionado,
                                      'fechaRegistro': DateTime.now()
                                          .toString()
                                          .substring(0, 10),
                                    });
                                  });
                                  Navigator.of(context).pop();
                                  _rolSeleccionado = null;

                                  // TODO: Aquí implementar lógica para guardar en base de datos
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorPrimario,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('Guardar'),
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
}
