// login.dart

// ignore_for_file: avoid_print // Si usas esta directiva

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Asumo que usas http aquí también si LoginPage está en este archivo
import 'dart:convert'; // Y convert

// Import para la inicialización de formatos de fecha
import 'package:intl/date_symbol_data_local.dart';

// Tus otras importaciones (si MyApp, LoginPage, y otras pantallas están definidas
// o importadas aquí)
// Por ejemplo, si MyApp y tus pantallas principales están definidas en otro archivo
// que luego importas aquí, o si están todas en login.dart:
import 'package:pos_proyecto/MODULOS/RECEPCION/pantallas/pantalla_principal_recepcion.dart';
import 'package:pos_proyecto/MODULOS/TRABAJO_SOCIAL/pantallas/pantalla_principal_ts.dart';
import 'package:pos_proyecto/MODULOS/MEDICO/pantallas/pantalla_agenda_medico.dart';
import 'regis_usuario.dart';


// --------- INICIO DE LA SECCIÓN A MODIFICAR / VERIFICAR en login.dart ---------

void main() async { // 1. Haz que main sea async
  WidgetsFlutterBinding.ensureInitialized(); // 2. Asegura que los bindings estén inicializados
  await initializeDateFormatting(null, null); // 3. Llama a initializeDateFormatting

  // Si quieres inicializar para un idioma específico, por ejemplo, Español (México):
  // await initializeDateFormatting('es_MX', null);
  // O para español genérico:
  // await initializeDateFormatting('es', null);

  // 4. Luego ejecuta tu app (asegúrate que MyApp esté definida o importada)
  runApp(const MyApp());
}

// --------- FIN DE LA SECCIÓN A MODIFICAR / VERIFICAR en login.dart ---------


// Aquí continuarían las definiciones de tus clases MyApp, LoginPage, _LoginPageState, etc.,
// si están todas en este archivo login.dart, como en el código completo que me mostraste antes.

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginPage(), // LoginPage sigue siendo el home de MyApp
      routes: {
        '/registro': (context) => const PaginaRegistroUsuario(),
        '/recepcion': (context) => const PantallaPrincipalRecepcion(),
        '/trabajo_social': (context) => const PantallaPrincipalTS(),
        '/medico_agenda': (context) => const PantallaAgendaMedico(),
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // ... (todo el código de _LoginPageState que ya tienes, incluyendo _login(), build(), etc.)
  // ... (asegúrate que las importaciones de http, convert, y las pantallas estén al inicio del archivo)

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      String email = _emailController.text.trim();
      String password = _passwordController.text;
      final String apiUrl = 'http://localhost:3000/api/usuarios/login';

      print('Intentando iniciar sesión con:');
      print('Email: $email');
      print('Password: $password');

      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "correo_electronico": email,
            "contrasena": password,
          }),
        );

        print('Código de estado HTTP: ${response.statusCode}');
        print('Respuesta completa: ${response.body}');

        if (!mounted) return;

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          String rol = data['usuario']['rol']
              .toString()
              .toLowerCase()
              .replaceAll(' ', '_');
          print('Login exitoso. Rol recibido (formateado): "$rol"');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login exitoso. Rol: $rol')),
          );

          switch (rol) {
            case 'recepcion':
              Navigator.pushReplacementNamed(context, '/recepcion');
              break;
            case 'trabajo_social':
              Navigator.pushReplacementNamed(context, '/trabajo_social');
              break;
            case 'doctor':
            case 'medico':
              Navigator.pushReplacementNamed(context, '/medico_agenda');
              break;
            default:
              print('Rol desconocido: $rol');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Rol no reconocido: $rol')),
              );
          }
        } else {
          final mensaje = jsonDecode(response.body)['message'] ?? 'Error desconocido del servidor';
          print('Error del servidor: $mensaje');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $mensaje')),
          );
        }
      } catch (e) {
        print('Excepción al conectar: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error de conexión con el servidor.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'Bienvenido a la familia CRI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'ejemplo@correo.com',
                      labelText: 'Correo Electrónico',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, ingresa tu correo electrónico';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Ingresa un correo electrónico válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, ingresa tu contraseña';
                      }
                      if (value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28.0),
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      textStyle: const TextStyle(fontSize: 18.0, color: Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: const Text('Iniciar Sesión', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 16.0),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/registro');
                    },
                    child: const Text('¿No tienes una cuenta? Regístrate'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}