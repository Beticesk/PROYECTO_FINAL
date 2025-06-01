// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pos_proyecto/MODULOS/TRABAJO_SOCIAL/pantallas/pantalla_principal_ts.dart';

import 'package:pos_proyecto/home.dart';
import 'package:pos_proyecto/login.dart';
import 'package:pos_proyecto/regis_usuario.dart';
import 'package:pos_proyecto/servicios_globales/servicio_conexion_bd.dart';
import 'package:pos_proyecto/MODULOS/RECEPCION/pantallas/pantalla_principal_recepcion.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final conectado = await ServicioConexionBD().abrirConexion();
  if (conectado) {
    print('✔️ Conexión exitosa a PostgreSQL');
  } else {
    
    print('❌ Error al conectar a PostgreSQL');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pos Proyecto',
      debugShowCheckedModeBanner: false,
      
      // LOCALIZACIÓN
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', ''),
      ],
      locale: const Locale('es'),

      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueAccent,
        brightness: Brightness.light,
      ),

      // Pantalla inicial: Login
       home: const  InicioScreen(),

      // Rutas
      routes: {
        '/login': (context) => const LoginPage(),
        '/registro': (context) => const PaginaRegistroUsuario(),
        '/recepcion': (context) => const PantallaPrincipalRecepcion(),
        '/trabajo_social': (context) => const PantallaPrincipalTS(),

      },
    );
  }
}
