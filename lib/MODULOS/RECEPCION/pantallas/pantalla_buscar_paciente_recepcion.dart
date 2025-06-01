// lib/modulos/recepcion/pantallas/pantalla_buscar_paciente_recepcion.dart
import 'package:flutter/material.dart';
import 'pantalla_ver_paciente_recepcion.dart';
import '../../../modelos_globales/modelo_paciente.dart';
import '../servicios/servicio_bd_recepcion.dart';
class PantallaBuscarPacienteRecepcion extends StatefulWidget {
  const PantallaBuscarPacienteRecepcion({super.key});

  @override
  State<PantallaBuscarPacienteRecepcion> createState() =>
      _PantallaBuscarPacienteRecepcionState();
}

class _PantallaBuscarPacienteRecepcionState
    extends State<PantallaBuscarPacienteRecepcion> {
  final ServicioBDRecepcion _servicioBD = ServicioBDRecepcion();
  final TextEditingController _terminoBusquedaController =
      TextEditingController();

  List<Paciente>? _resultadosBusqueda;
  bool _isLoading = false;
  String? _mensajeError;
  bool _busquedaRealizada = false; // Para saber si mostrar "No se encontraron..."

  @override
  void dispose() {
    _terminoBusquedaController.dispose();
    super.dispose();
  }

  Future<void> _buscarPacientes() async {
    if (_terminoBusquedaController.text.trim().isEmpty) {
      setState(() {
        _resultadosBusqueda = []; // Limpia resultados si la búsqueda está vacía
        _busquedaRealizada = true; 
        _mensajeError = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _mensajeError = null;
      _busquedaRealizada = true;
    });

    try {
      final pacientes = await _servicioBD
          .buscarPacientesPorNombre(_terminoBusquedaController.text.trim());
      if (mounted) {
        setState(() {
          _resultadosBusqueda = pacientes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _mensajeError = 'Error al buscar pacientes: $e';
          _resultadosBusqueda = []; // Limpiar resultados en caso de error
        });
      }
    }
  }

  void _navegarADetallePaciente(int pacienteId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Ahora navega a la pantalla correcta para Recepción
        builder: (context) => PantallaVerPacienteRecepcion(pacienteId: pacienteId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Paciente'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _terminoBusquedaController,
              decoration: InputDecoration(
                labelText: 'Nombre del Paciente',
                hintText: 'Ingrese nombre o apellido',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _buscarPacientes,
                ),
              ),
              onSubmitted: (_) => _buscarPacientes(), // Permite buscar con Enter
            ),
            const SizedBox(height: 16.0),
            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Buscar'),
              onPressed: _buscarPacientes,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12.0)),
            ),
            const SizedBox(height: 20.0),
            _buildResultadosBusqueda(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultadosBusqueda() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_mensajeError != null) {
      return Center(
          child: Text(_mensajeError!, style: const TextStyle(color: Colors.red)));
    }

    if (!_busquedaRealizada) {
      return const Center(child: Text('Ingrese un término de búsqueda y presione "Buscar".'));
    }
    
    if (_resultadosBusqueda == null || _resultadosBusqueda!.isEmpty) {
      return const Center(child: Text('No se encontraron pacientes con ese nombre.'));
    }

    return Expanded(
      child: ListView.builder(
        itemCount: _resultadosBusqueda!.length,
        itemBuilder: (context, index) {
          final paciente = _resultadosBusqueda![index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              title: Text(paciente.nombreCompleto),
              subtitle: Text(
                  'ID: ${paciente.pacienteID} - Tel: ${paciente.contactoTelefono ?? "N/A"}'),
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