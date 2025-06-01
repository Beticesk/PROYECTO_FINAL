import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaginaRegistroUsuario extends StatefulWidget {
  const PaginaRegistroUsuario({super.key});

  @override
  State<PaginaRegistroUsuario> createState() => _PaginaRegistroUsuarioState();
}

class _PaginaRegistroUsuarioState extends State<PaginaRegistroUsuario> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreUsuarioController = TextEditingController();
  final TextEditingController _correoElectronicoController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  String? _selectedRol;

  final List<String> _roles = [
    'PACIENTE',
    'RECEPCION',
    'TRABAJO SOCIAL',
    'ENFERMERIA',
    'DOCTOR'
  ];

  bool _isLoading = false;

  @override
  void dispose() {
    _nombreUsuarioController.dispose();
    _correoElectronicoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String nombreUsuario = _nombreUsuarioController.text;
      String correo = _correoElectronicoController.text;
      String contrasena = _contrasenaController.text;
      String rol = _selectedRol!;

      final String apiUrl = 'http://localhost:3000/api/usuarios/registrar';

      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({
            'nombre_usuario': nombreUsuario,
            'correo_electronico': correo,
            'contrasena': contrasena,
            'rol': rol,
          }),
        );

        setState(() {
          _isLoading = false;
        });

        final responseData = jsonDecode(response.body);
        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'] ?? 'Usuario registrado exitosamente!')),
          );
          _formKey.currentState!.reset();
          _nombreUsuarioController.clear();
          _correoElectronicoController.clear();
          _contrasenaController.clear();
          setState(() => _selectedRol = null);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${responseData['message'] ?? 'No se pudo registrar el usuario.'}')),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Registro de Usuario', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Crear Cuenta de Usuario',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color:  Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Nombre
                    TextFormField(
                      controller: _nombreUsuarioController,
                      decoration: _inputDecoration('Nombre completo', Icons.person_outline),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Por favor, ingresa el nombre del usuario'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Correo
                    TextFormField(
                      controller: _correoElectronicoController,
                      decoration: _inputDecoration('Correo electrónico', Icons.email_outlined),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Ingresa el correo electrónico';
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Correo electrónico inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Contraseña
                    TextFormField(
                      controller: _contrasenaController,
                      decoration: _inputDecoration('Contraseña', Icons.lock_outline),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Ingresa una contraseña';
                        if (value.length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Rol
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration('Rol del usuario', Icons.admin_panel_settings_outlined),
                      value: _selectedRol,
                      isExpanded: true,
                      items: _roles.map((rol) {
                        return DropdownMenuItem<String>(
                          value: rol,
                          child: Text(rol),
                        );
                      }).toList(),
                      onChanged: (newValue) => setState(() => _selectedRol = newValue),
                      validator: (value) => value == null ? 'Selecciona un rol' : null,
                    ),
                    const SizedBox(height: 30),

                    // Botón Registrar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _registerUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Registrar Usuario',
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blue),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.blue, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
