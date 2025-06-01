// lib/modulos/recepcion/pantallas/pantalla_caja_pendientes.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Asegúrate que las rutas de importación sean correctas
import '../../../modelos_globales/modelo_paciente.dart'; // Para pasar a la pantalla de registro de pago
import '../servicios/servicio_bd_recepcion.dart';
import './pantalla_registrar_pago_recepcion.dart'; // Para navegar

class PantallaCajaPendientes extends StatefulWidget {
  const PantallaCajaPendientes({super.key});

  @override
  State<PantallaCajaPendientes> createState() => _PantallaCajaPendientesState();
}

class _PantallaCajaPendientesState extends State<PantallaCajaPendientes> {
  final ServicioBDRecepcion _servicioBD = ServicioBDRecepcion();
  List<Map<String, dynamic>>? _listaPacientes;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarPacientesConRecomendacion();
  }

  Future<void> _cargarPacientesConRecomendacion() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final pacientes = await _servicioBD.obtenerPacientesConRecomendacionExencion();
      if (mounted) {
        setState(() {
          _listaPacientes = pacientes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error al cargar pacientes para caja: $e';
        });
      }
    }
  }

  Future<void> _navegarARegistrarPago(int pacienteId) async {
    // Necesitamos el objeto Paciente completo para PantallaRegistrarPagoRecepcion
    // Podríamos hacer que obtenerPacientesConRecomendacionExencion devuelva objetos Paciente
    // o cargarlo aquí. Por simplicidad, lo cargaremos aquí.
    // Idealmente, el servicio devolvería los datos necesarios o el objeto Paciente directamente.
    
    // Muestra un indicador de carga mientras se obtienen los datos completos del paciente
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      Paciente? paciente = await _servicioBD.obtenerPacientePorId(pacienteId);
      Navigator.of(context).pop(); // Cierra el diálogo de carga

      if (mounted && paciente != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PantallaRegistrarPagoRecepcion(paciente: paciente),
          ),
        ).then((_) {
          // Al regresar, refrescamos la lista, ya que el paciente podría ya no estar pendiente
          _cargarPacientesConRecomendacion();
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudieron cargar los detalles completos del paciente.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Cierra el diálogo de carga
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar paciente para pago: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return "N/A";
    return DateFormat('dd/MM/yyyy', 'es_ES').format(fecha.toLocal());
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caja - Pendientes de Exención'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarPacientesConRecomendacion,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_error!, style: const TextStyle(color: Colors.red))));
    }
    if (_listaPacientes == null || _listaPacientes!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No hay pacientes con recomendación de exención pendiente de registrar en caja.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _listaPacientes!.length,
      itemBuilder: (context, index) {
        final pacienteData = _listaPacientes![index];
        final String nombreCompleto = pacienteData['nombrecompleto'] ?? 'N/A';
        final int pacienteId = pacienteData['pacienteid'];
        final DateTime? fechaEntrevista = pacienteData['fechaentrevista'];
        final String justificacion = pacienteData['justificacionexencion'] ?? 'Sin justificación detallada.';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: ListTile(
            title: Text(nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text('Entrevista: ${_formatearFecha(fechaEntrevista)}\nJustificación TS: $justificacion', overflow: TextOverflow.ellipsis, maxLines: 2,),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _navegarARegistrarPago(pacienteId);
            },
          ),
        );
      },
    );
  }
}