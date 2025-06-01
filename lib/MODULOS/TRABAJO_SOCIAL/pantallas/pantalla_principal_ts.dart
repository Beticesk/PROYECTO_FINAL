// lib/modulos/TRABAJO_SOCIAL/pantallas/pantalla_principal_ts.dart
import 'package:flutter/material.dart';
// Asegúrate que las rutas de importación sean correctas
import '../../../modelos_globales/modelo_paciente.dart';
import '../servicios/servicio_bd_trabajo_social.dart';
import './pantalla_detalle_paciente_ts.dart'; // Para navegar al detalle

class PantallaPrincipalTS extends StatefulWidget {
  const PantallaPrincipalTS({super.key});

  @override
  State<PantallaPrincipalTS> createState() => _PantallaPrincipalTSState();
}

class _PantallaPrincipalTSState extends State<PantallaPrincipalTS> {
  final ServicioBDTrabajoSocial _servicioBD = ServicioBDTrabajoSocial();
  List<Paciente>? _listaPacientesPendientes; // Lista de pacientes sin entrevista hoy
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarPacientesPendientesDeEntrevista();
  }

 Future<void> _cargarPacientesPendientesDeEntrevista() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Llama al método modificado del servicio
      final pacientes = await _servicioBD.obtenerPacientesSinEntrevista(); // <--- Asegúrate que el nombre del método coincida
      if (mounted) {
        setState(() {
          _listaPacientesPendientes = pacientes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error al cargar pacientes pendientes: $e';
        });
      }
    }
  }

  void _navegarADetallePaciente(int pacienteId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PantallaDetallePacienteTS(pacienteId: pacienteId),
      ),
    ).then((_) {
      // Al regresar de la pantalla de detalle (y posiblemente de registrar una entrevista),
      // volvemos a cargar la lista para que se actualice.
      _cargarPacientesPendientesDeEntrevista();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TS - Pacientes para Entrevista Hoy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar Lista',
            onPressed: _cargarPacientesPendientesDeEntrevista,
          ),
        ],
      ),
      body: _buildBody(),
      // Opcional: Puedes añadir un FloatingActionButton para una búsqueda general de pacientes
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //  Implementar navegación a una pantalla de búsqueda de pacientes general
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(content: Text('Funcionalidad de búsqueda no implementada aún.')),
      //     );
      //   },
      //   tooltip: 'Buscar Paciente',
      //   child: const Icon(Icons.search),
      // ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16)),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Intentar de Nuevo'),
                onPressed: _cargarPacientesPendientesDeEntrevista,
              )
            ],
          ),
        ),
      );
    }
    if (_listaPacientesPendientes == null || _listaPacientesPendientes!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_search_outlined, size: 60, color: Colors.grey),
              const SizedBox(height: 10),
              const Text(
                'No hay pacientes registrados hoy que necesiten entrevista.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Refrescar'),
                onPressed: _cargarPacientesPendientesDeEntrevista,
              )
            ],
          ),
        ),
      );
    }

    // Si tenemos pacientes, los mostramos en una lista
    return RefreshIndicator(
      onRefresh: _cargarPacientesPendientesDeEntrevista,
      child: ListView.builder(
        itemCount: _listaPacientesPendientes!.length,
        itemBuilder: (context, index) {
          final paciente = _listaPacientesPendientes![index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            elevation: 2.0,
            child: ListTile(
              leading: CircleAvatar(
                child: Text(paciente.nombreCompleto.isNotEmpty ? paciente.nombreCompleto[0].toUpperCase() : '?'),
              ),
              title: Text(paciente.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text('ID: ${paciente.pacienteID} - Tel: ${paciente.contactoTelefono ?? "N/A"}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: () {
                if (paciente.pacienteID != null) {
                  _navegarADetallePaciente(paciente.pacienteID!);
                }
              },
            ),
          );
        },
      ),
    );
  }
}