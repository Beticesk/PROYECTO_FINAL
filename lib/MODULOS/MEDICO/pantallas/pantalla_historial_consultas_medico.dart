// lib/modulos/medico/pantallas/pantalla_historial_consultas_medico.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Asegúrate que las rutas de importación sean correctas
import '../../../modelos_globales/modelo_paciente.dart'; // Para obtener el nombre del paciente
import '../servicios/servicio_bd_medico.dart';

class PantallaHistorialConsultasMedico extends StatefulWidget {
  final int pacienteId;
  final String? nombrePaciente; // Opcional: pasar el nombre para el título inmediato

  const PantallaHistorialConsultasMedico({
    super.key, 
    required this.pacienteId,
    this.nombrePaciente,
  });

  @override
  State<PantallaHistorialConsultasMedico> createState() =>
      _PantallaHistorialConsultasMedicoState();
}

class _PantallaHistorialConsultasMedicoState extends State<PantallaHistorialConsultasMedico> {
  final ServicioBDMedico _servicioBD = ServicioBDMedico();
  
  List<Map<String, dynamic>>? _historialCitas;
  Paciente? _paciente; // Para mostrar el nombre si no se pasó
  bool _isLoading = true;
  String? _errorCarga;

  @override
  void initState() {
    super.initState();
    _cargarDatosHistorial();
  }

  Future<void> _cargarDatosHistorial() async {
    setState(() {
      _isLoading = true;
      _errorCarga = null;
    });
    try {
      // Si no se pasó el nombre del paciente, cargarlo
      if (widget.nombrePaciente == null) {
        _paciente = await _servicioBD.obtenerDetallesCompletosPacienteParaMedico(widget.pacienteId)
            .then((datos) => datos?['paciente'] as Paciente?);
      }
      
      _historialCitas = await _servicioBD.obtenerHistorialCitasPacienteParaMedico(widget.pacienteId);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorCarga = 'Error al cargar el historial de consultas: $e';
        });
      }
    }
  }

  String _formatearFecha(DateTime? fecha, {bool incluirHora = false}) {
    if (fecha == null) return "N/A";
    String formato = incluirHora ? 'dd/MM/yyyy HH:mm' : 'dd/MM/yyyy';
    return DateFormat(formato, 'es_ES').format(fecha.toLocal());
  }

  Color _getColorPorEstado(String? estado) {
    switch (estado) {
      case 'Realizada':
        return Colors.green.shade700;
      case 'Cancelada':
      case 'No Asistio': // Asegúrate que este sea el valor exacto de tu enum/string
        return Colors.red.shade700;
      case 'Programada':
      case 'Confirmada':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    String tituloAppBar = widget.nombrePaciente ?? _paciente?.nombreCompleto ?? 'Historial';
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de Consultas - $tituloAppBar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatosHistorial,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorCarga != null
              ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_errorCarga!, style: const TextStyle(color: Colors.red))))
              : _historialCitas == null || _historialCitas!.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Este paciente no tiene historial de consultas registradas.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
                      ),
                    )
                  : _buildListaHistorial(),
    );
  }

  Widget _buildListaHistorial() {
    return ListView.separated(
      padding: const EdgeInsets.all(8.0),
      itemCount: _historialCitas!.length,
      itemBuilder: (context, index) {
        final citaMap = _historialCitas![index];
        final DateTime fechaHoraCita = citaMap['fechahoracita'];
        final String tipoConsulta = citaMap['tipoconsulta'] ?? 'N/A';
        final String estadoCita = citaMap['estadocita'] ?? 'N/A';
        final String? profesional = citaMap['profesionalasignado'];
        final String? observacionMedico = citaMap['frecuenciasiguientecitarecomendada'];

        return Card(
          elevation: 2.0,
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formatearFecha(fechaHoraCita, incluirHora: true)} - $tipoConsulta',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('Estado: ', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                    Text(estadoCita, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _getColorPorEstado(estadoCita))),
                  ],
                ),
                if (profesional != null && profesional.isNotEmpty) 
                  Text('Atendió: $profesional', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                
                if (observacionMedico != null && observacionMedico.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Observación/Seguimiento Médico:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color)),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                    child: Text(observacionMedico, style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color)),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 2), // Un pequeño separador
    );
  }
}