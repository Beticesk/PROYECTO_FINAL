// lib/modulos/medico/pantallas/pantalla_gestion_consulta.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Asegúrate que las rutas de importación sean correctas
import '../../../modelos_globales/modelo_paciente.dart';
import '../../../modelos_globales/modelo_entrevista_social.dart';
import '../servicios/servicio_bd_medico.dart';

class PantallaGestionConsulta extends StatefulWidget {
  final int pacienteId;
  final int citaId;
  final DateTime fechaHoraCitaOriginal;
  final String tipoConsultaOriginal;

  const PantallaGestionConsulta({
    super.key,
    required this.pacienteId,
    required this.citaId,
    required this.fechaHoraCitaOriginal,
    required this.tipoConsultaOriginal,
  });

  @override
  State<PantallaGestionConsulta> createState() =>
      _PantallaGestionConsultaState();
}

class _PantallaGestionConsultaState extends State<PantallaGestionConsulta> {
  final ServicioBDMedico _servicioBD = ServicioBDMedico();

  Paciente? _paciente;
  EntrevistaSocial? _entrevistaSocial;
  List<Map<String, dynamic>>? _historialCitas;

  bool _isLoading = true;
  String? _errorCarga;

  final TextEditingController _frecuenciaController = TextEditingController();
  bool _certificadoEntregado = false;
  String? _frecuenciaSeleccionada;

  final List<String> _opcionesFrecuencia = [
    "Presenta avances",
    "Acude regularmente",
    "Requiere seguimiento",
    "Continuar con plan actual",
    "Revaloración en 1 semana",
    "Revaloración en 2 semanas",
    "Revaloración en 1 mes",
    "Alta médica",
  ];

  @override
  void initState() {
    super.initState();
    _cargarTodosLosDatosCompletos();
  }

  Future<void> _cargarTodosLosDatosCompletos() async {
    setState(() { _isLoading = true; _errorCarga = null; });
    try {
      final datosPacienteYEntrevista = await _servicioBD.obtenerDetallesCompletosPacienteParaMedico(widget.pacienteId);
      final historial = await _servicioBD.obtenerHistorialCitasPacienteParaMedico(widget.pacienteId);

      if (mounted) {
        setState(() {
          if (datosPacienteYEntrevista != null) {
            _paciente = datosPacienteYEntrevista['paciente'];
            _entrevistaSocial = datosPacienteYEntrevista['entrevista'];
            if (_paciente != null) {
              _certificadoEntregado = _paciente!.certificadoDiscapacidadEntreg;
            }
          }
          _historialCitas = historial;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; _errorCarga = 'Error al cargar datos: $e'; });
      }
    }
  }

  Future<void> _finalizarConsultaAccion() async {
    setState(() => _isLoading = true);
    String? notaFinalFrecuencia = _frecuenciaController.text.trim();
    if (notaFinalFrecuencia.isEmpty && _frecuenciaSeleccionada != null) {
      notaFinalFrecuencia = _frecuenciaSeleccionada;
    }

    try {
      await _servicioBD.finalizarConsulta(
        citaId: widget.citaId,
        nuevoEstadoCita: 'Realizada',
        frecuenciaProximaCita: notaFinalFrecuencia,
        pacienteId: widget.pacienteId,
        certificadoEntregado: _certificadoEntregado,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consulta finalizada y actualizada.'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true); // Devuelve true para refrescar agenda
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al finalizar consulta: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  String _formatearFecha(DateTime? fecha, {bool incluirHora = false}) {
    if (fecha == null) return "N/A";
    String formato = incluirHora ? 'dd/MM/yyyy HH:mm' : 'dd/MM/yyyy';
    return DateFormat(formato, 'es_ES').format(fecha.toLocal());
  }

  @override
  void dispose(){
    _frecuenciaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_paciente?.nombreCompleto ?? 'Gestión de Consulta'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargarTodosLosDatosCompletos)
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorCarga != null
              ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_errorCarga!, style: const TextStyle(color: Colors.red))))
              : _paciente == null
                  ? const Center(child: Text('No se pudo cargar la información del paciente.'))
                  : _buildContenidoConsulta(),
    );
  }

  Widget _buildContenidoConsulta() {
    return ListView( // Permite scroll si el contenido es mucho
      padding: const EdgeInsets.all(16.0),
      children: [
        // --- Detalles de la Cita Actual y Paciente ---
        Text('Paciente: ${_paciente!.nombreCompleto}', style: Theme.of(context).textTheme.titleLarge),
        Text('Cita Actual (ID: ${widget.citaId}): ${widget.tipoConsultaOriginal}'),
        Text('Fecha: ${_formatearFecha(widget.fechaHoraCitaOriginal, incluirHora: true)}'),
        const SizedBox(height: 10),
        const Divider(),

        // --- Info Entrevista Socioeconómica (TS) ---
        if (_entrevistaSocial != null) ...[
          _buildTituloSeccion("Info. Entrevista Socioeconómica (TS)"),
          _buildInfoFila('Recomienda Exención:', _entrevistaSocial!.recomiendaExencion ? "Sí" : "No"),
          if (_entrevistaSocial!.recomiendaExencion && _entrevistaSocial!.justificacionExencion != null)
            _buildInfoFila('Justificación TS:', _entrevistaSocial!.justificacionExencion!),
          const SizedBox(height: 10),
          const Divider(),
        ],
        
        // --- Historial de Consultas ---
        _buildTituloSeccion("Historial de Consultas Anteriores"),
        _buildHistorialCitasWidget(), // Nuevo widget para mostrar el historial
        const SizedBox(height: 10),
        const Divider(),

        // --- Acciones y Observaciones del Médico para la Consulta Actual ---
        _buildTituloSeccion('Finalizar Consulta Actual'),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Observación / Seguimiento (Opcional)', border: OutlineInputBorder()),
          value: _frecuenciaSeleccionada,
          hint: const Text('Seleccionar frase o escribir abajo'),
          isExpanded: true,
          items: _opcionesFrecuencia.map((String valor) => DropdownMenuItem<String>(value: valor, child: Text(valor))).toList(),
          onChanged: (String? nuevoValor) {
            setState(() {
              _frecuenciaSeleccionada = nuevoValor;
              if (nuevoValor != null) _frecuenciaController.clear();
            });
          },
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _frecuenciaController,
          decoration: const InputDecoration(labelText: 'Nota Adicional / Frecuencia (Opcional)', border: OutlineInputBorder(), hintText: 'Ej: Volver en 2 semanas...'),
          maxLines: 3,
          onChanged: (text) {
            if (text.isNotEmpty && _frecuenciaSeleccionada != null) {
              setState(() => _frecuenciaSeleccionada = null);
            }
          },
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Certificado de Discapacidad Entregado'),
          value: _certificadoEntregado,
          onChanged: (bool value) => setState(() => _certificadoEntregado = value),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Marcar como REALIZADA y Guardar'),
          onPressed: _isLoading ? null : _finalizarConsultaAccion,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16.0)),
        ),
      ],
    );
  }

  Widget _buildTituloSeccion(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
      child: Text(titulo, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoFila(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$etiqueta ', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          Expanded(child: Text(valor, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
  
  Widget _buildHistorialCitasWidget() {
    if (_historialCitas == null || _historialCitas!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('No hay consultas anteriores registradas para este paciente.'),
      );
    }
    // Para no hacer la pantalla demasiado larga, podríamos limitar el número de citas mostradas
    // o ponerlas dentro de un ExpansionTile. Aquí un ejemplo con ExpansionTile.
    return ExpansionTile(
      title: Text("Ver ${_historialCitas!.length} consulta(s) anterior(es)", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      tilePadding: EdgeInsets.zero,
      children: _historialCitas!.map((citaMap) {
        final DateTime fechaHoraCita = citaMap['fechahoracita'];
        final String tipoConsulta = citaMap['tipoconsulta'] ?? 'N/A';
        final String estadoCita = citaMap['estadocita'] ?? 'N/A';
        final String? observacionMedico = citaMap['frecuenciasiguientecitarecomendada'];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          elevation: 1.0,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formatearFecha(fechaHoraCita, incluirHora: true)} - $tipoConsulta',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text('Estado: $estadoCita', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13, color: estadoCita == 'Realizada' ? Colors.green : Colors.grey)),
                if (observacionMedico != null && observacionMedico.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Observación/Seguimiento:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.blueGrey[700])),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(observacionMedico, style: TextStyle(fontSize: 13, color: Colors.blueGrey[600])),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}