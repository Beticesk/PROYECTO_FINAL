// lib/modulos/recepcion/pantallas/pantalla_principal_recepcion.dart
import 'package:flutter/material.dart';
import 'package:pos_proyecto/MODULOS/RECEPCION/pantallas/pantalla_buscar_paciente_recepcion.dart';
import 'package:pos_proyecto/MODULOS/RECEPCION/pantallas/pantalla_caja_pendientes.dart';
import './pantalla_agenda_recepcion.dart';
import './pantalla_registrar_paciente.dart';


class PantallaPrincipalRecepcion extends StatelessWidget {
  const PantallaPrincipalRecepcion({super.key});

  void _navegarARegistrarPaciente(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PantallaRegistrarPaciente()),
    );
  }

  // Placeholder para otras navegaciones
  void _navegarABuscarPaciente(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const PantallaBuscarPacienteRecepcion()),
  );
}

void _navegarAAgenda(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PantallaAgendaRecepcion()),
    );
  }

void _navegarACaja(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PantallaCajaPendientes()),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recepción - Sistema de Gestión'),
        // Opcional: Puedes añadir un botón de cerrar sesión o perfil aquí
      ),
      body: GridView.count(
        crossAxisCount: 2, // Dos columnas
        padding: const EdgeInsets.all(16.0),
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        children: <Widget>[
          _buildBotonMenu(
            contexto: context,
            icono: Icons.person_add_alt_1,
            etiqueta: 'Registrar Paciente',
            accion: () => _navegarARegistrarPaciente(context),
          ),
          _buildBotonMenu(
            contexto: context,
            icono: Icons.search,
            etiqueta: 'Buscar Paciente',
            accion: () => _navegarABuscarPaciente(context),
          ),
          _buildBotonMenu(
            contexto: context,
            icono: Icons.calendar_today,
            etiqueta: 'Agenda / Citas',
            accion: () => _navegarAAgenda(context),
          ),
          _buildBotonMenu(
            contexto: context,
            icono: Icons.point_of_sale,
            etiqueta: 'Caja / Pagos',
            accion: () => _navegarACaja(context),
          ),
          // Puedes añadir más botones para otras funcionalidades de recepción
        ],
      ),
    );
  }

  Widget _buildBotonMenu({
    required BuildContext contexto,
    required IconData icono,
    required String etiqueta,
    required VoidCallback accion,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        // primary: Theme.of(contexto).colorScheme.surface, // Color de fondo del botón
        // onPrimary: Theme.of(contexto).colorScheme.onSurface, // Color del texto e icono
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.all(16.0),
      ).copyWith(
         backgroundColor: WidgetStateProperty.all(Theme.of(contexto).colorScheme.surfaceContainerHighest),
         foregroundColor: WidgetStateProperty.all(Theme.of(contexto).colorScheme.onSurfaceVariant),
      ),
      onPressed: accion,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(icono, size: 48.0),
          const SizedBox(height: 12.0),
          Text(
            etiqueta,
            textAlign: TextAlign.center,
            style: Theme.of(contexto).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500
            ),
          ),
        ],
      ),
    );
  }
}