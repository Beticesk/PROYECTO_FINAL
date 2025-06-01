// lib/modulos/medico/pantallas/pantalla_detalle_paciente_medico.dart
// ignore_for_file: unused_element // Puedes quitar esto si _buildInfoFilaBool ya no da warning

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../modelos_globales/modelo_paciente.dart';
import '../../../modelos_globales/modelo_entrevista_social.dart';
import '../servicios/servicio_bd_medico.dart';
import './pantalla_historial_consultas_medico.dart';

class PantallaDetallePacienteMedico extends StatefulWidget {
  final int pacienteId;
  const PantallaDetallePacienteMedico({super.key, required this.pacienteId});

  @override
  State<PantallaDetallePacienteMedico> createState() =>
      _PantallaDetallePacienteMedicoState();
}

class _PantallaDetallePacienteMedicoState extends State<PantallaDetallePacienteMedico> {
  final ServicioBDMedico _servicioBD = ServicioBDMedico();
  
  Paciente? _paciente;
  EntrevistaSocial? _entrevistaSocial;
  // Ya NO necesitamos _historialCitas aquí como variable de estado

  bool _isLoading = true;
  String? _errorCarga;

  @override
  void initState() {
    super.initState();
    _cargarDatosPrincipales(); 
  }

  Future<void> _cargarDatosPrincipales() async {
    setState(() { _isLoading = true; _errorCarga = null; });
    try {
      final datosPacienteYEntrevista = await _servicioBD.obtenerDetallesCompletosPacienteParaMedico(widget.pacienteId);

      if (mounted) {
        setState(() {
          if (datosPacienteYEntrevista != null) {
            _paciente = datosPacienteYEntrevista['paciente'];
            _entrevistaSocial = datosPacienteYEntrevista['entrevista'];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorCarga = 'Error al cargar datos del paciente: $e';
        });
      }
    }
  }

  // Método para formatear fecha (DEFINIDO UNA SOLA VEZ)
  String _formatearFecha(DateTime? fecha, {bool incluirHora = false}) { 
    if (fecha == null) return "N/A";
    String formato = incluirHora ? 'dd/MM/yyyy HH:mm' : 'dd/MM/yyyy';
    return DateFormat(formato, 'es_ES').format(fecha.toLocal());
  }

  // Método de navegación para el historial (DEFINIDO UNA SOLA VEZ)
  void _navegarAHistorialConsultas() {
    if (_paciente != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PantallaHistorialConsultasMedico(
            pacienteId: widget.pacienteId,
            nombrePaciente: _paciente!.nombreCompleto, 
          ),
        ),
      );
    }
  }

  // Métodos auxiliares para construir la UI (DEFINIDOS UNA SOLA VEZ)
  Widget _buildTituloSeccion(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(titulo, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoFila(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$etiqueta ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Expanded(child: SelectableText(valor, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildInfoFilaBool(String etiqueta, bool valor) {
     return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$etiqueta ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(valor ? 'Sí' : 'No', style: TextStyle(fontSize: 14, color: valor ? Colors.green.shade700 : Colors.red.shade700)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_paciente?.nombreCompleto ?? 'Detalle Paciente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatosPrincipales,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorCarga != null
              ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_errorCarga!, style: const TextStyle(color: Colors.red))))
              : _paciente == null
                  ? const Center(child: Text('No se encontró información del paciente.'))
                  : _buildContenidoDetalle(),
    );
  }

  Widget _buildContenidoDetalle() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: <Widget>[
        // --- Sección Datos Generales del Paciente ---
        _buildTituloSeccion("Datos del Paciente"),
        _buildInfoFila('ID Paciente:', widget.pacienteId.toString()),
        _buildInfoFila('Nombre Completo:', _paciente!.nombreCompleto),
        _buildInfoFila('Fecha de Nacimiento:', _formatearFecha(_paciente!.fechaNacimiento)),
        _buildInfoFila('Teléfono:', _paciente!.contactoTelefono ?? "N/A"),
        _buildInfoFila('Email:', _paciente!.contactoEmail ?? "N/A"),
        _buildInfoFila('Idioma:', _paciente!.idioma ?? "N/A"),
        _buildInfoFilaBool('Documentación Incompleta:', _paciente!.documentacionIncompleta),
        _buildInfoFilaBool('Solicitó Certificado Discap.:', _paciente!.certificadoDiscapacidadSol),
        _buildInfoFilaBool('Certificado Discap. Entregado:', _paciente!.certificadoDiscapacidadEntreg),
        _buildInfoFila('Inicio Tratamiento:', _formatearFecha(_paciente!.fechaInicioTratamientoGeneral)),
        _buildInfoFila('Fin Tratamiento:', _formatearFecha(_paciente!.fechaFinTratamientoGeneral)),
        _buildInfoFila('Registrado el:', _formatearFecha(_paciente!.fechaRegistroSistema, incluirHora: true)),
        const SizedBox(height: 16),
        const Divider(),

        // --- Sección Entrevista Socioeconómica (TS) ---
        _buildTituloSeccion("Info. Entrevista Socioeconómica (TS)"),
        
        if (_entrevistaSocial != null) ...[
          _buildInfoFila('Fecha Entrevista:', _formatearFecha(_entrevistaSocial!.fechaEntrevista, incluirHora: true)),
          _buildInfoFilaBool('Recomienda Exención:', _entrevistaSocial!.recomiendaExencion),
          if (_entrevistaSocial!.recomiendaExencion && 
              _entrevistaSocial!.justificacionExencion != null && 
              _entrevistaSocial!.justificacionExencion!.isNotEmpty)
            _buildInfoFila('Justificación TS:', _entrevistaSocial!.justificacionExencion!),
          ExpansionTile(
            title: const Text(
              'Ver Contenido Completo de Entrevista',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            children: [
                Container(
                  padding: const EdgeInsets.all(10.0),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300)
                  ),
                  child: SelectableText(
                    _entrevistaSocial!.contenidoEntrevista,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                )
            ],
          )
        ] else ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('No hay entrevista socioeconómica registrada para este paciente.'),
          ),
        ],
        const SizedBox(height: 16),
        const Divider(),

        // --- BOTÓN PARA VER HISTORIAL ---
        _buildTituloSeccion("Historial"),
        ElevatedButton.icon(
          icon: const Icon(Icons.history_edu_outlined),
          label: const Text('Ver Historial de Consultas'),
          onPressed: _navegarAHistorialConsultas,
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
        ),
        const SizedBox(height: 20),
        // Aquí podrías añadir otros botones de acción para el médico
      ],
    );
  }
}