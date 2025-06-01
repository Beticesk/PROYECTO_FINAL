// lib/modulos/TRABAJO_SOCIAL/pantallas/pantalla_ver_entrevista_solo_lectura.dart
import 'package:flutter/material.dart';
// Asegúrate que las rutas de importación sean correctas
import '../../../modelos_globales/modelo_entrevista_social.dart';
import '../../../modelos_globales/modelo_paciente.dart';
import '../servicios/servicio_bd_trabajo_social.dart'; // Para cargar datos del paciente

class PantallaVerEntrevistaSoloLectura extends StatefulWidget {
  final EntrevistaSocial entrevista;

  const PantallaVerEntrevistaSoloLectura({super.key, required this.entrevista});

  @override
  State<PantallaVerEntrevistaSoloLectura> createState() => _PantallaVerEntrevistaSoloLecturaState();
}

class _PantallaVerEntrevistaSoloLecturaState extends State<PantallaVerEntrevistaSoloLectura> {
  final ServicioBDTrabajoSocial _servicioBD = ServicioBDTrabajoSocial();
  Paciente? _paciente;
  bool _isLoadingPaciente = true;
  String? _errorCargaPaciente;

  @override
  void initState() {
    super.initState();
    _cargarDatosDelPaciente();
  }

  Future<void> _cargarDatosDelPaciente() async {
    setState(() {
      _isLoadingPaciente = true;
      _errorCargaPaciente = null;
    });
    try {
      // Usamos el pacienteID de la entrevista para cargar los datos del paciente
      final pacienteCargado = await _servicioBD.obtenerPacientePorId(widget.entrevista.pacienteID);
      if (mounted) {
        setState(() {
          _paciente = pacienteCargado;
          _isLoadingPaciente = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPaciente = false;
          _errorCargaPaciente = 'Error al cargar datos del paciente: $e';
        });
      }
    }
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return "N/A";
    // Puedes usar el paquete intl para un formateo más avanzado si lo necesitas:
    // return DateFormat('dd/MM/yyyy HH:mm').format(fecha.toLocal());
    return '${fecha.toLocal().day.toString().padLeft(2, '0')}/${fecha.toLocal().month.toString().padLeft(2, '0')}/${fecha.toLocal().year} ${fecha.toLocal().hour.toString().padLeft(2, '0')}:${fecha.toLocal().minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de Entrevista ${_isLoadingPaciente || _paciente == null ? "" : "- ${_paciente!.nombreCompleto}"}'),
      ),
      body: _isLoadingPaciente
          ? const Center(child: CircularProgressIndicator())
          : _errorCargaPaciente != null
              ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_errorCargaPaciente!, style: const TextStyle(color: Colors.red))))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: <Widget>[
                      if (_paciente != null) ...[
                        Text('Paciente: ${_paciente!.nombreCompleto}', style: Theme.of(context).textTheme.titleLarge),
                        Text('ID Paciente: ${widget.entrevista.pacienteID}'),
                        const SizedBox(height: 16),
                      ] else ... [
                        Text('ID Paciente: ${widget.entrevista.pacienteID}', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 16),
                      ],
                      
                      _buildInfoSeccion('Fecha de Entrevista:', _formatearFecha(widget.entrevista.fechaEntrevista)),
                      const SizedBox(height: 16),
                      
                      const Text(
                        'Contenido de la Entrevista:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[100], // Un fondo ligero para el texto
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: SelectableText(
                          widget.entrevista.contenidoEntrevista,
                          style: const TextStyle(fontSize: 15, height: 1.5), // Mejor interlineado para lectura
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      _buildInfoSeccion(
                        '¿Recomienda Exención de Pago?:', 
                        widget.entrevista.recomiendaExencion ? "Sí" : "No",
                        valorFontSize: 16
                      ),
                      
                      if (widget.entrevista.recomiendaExencion && widget.entrevista.justificacionExencion != null && widget.entrevista.justificacionExencion!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Justificación de la Exención:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                         Container(
                          padding: const EdgeInsets.all(12.0),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: SelectableText(
                            widget.entrevista.justificacionExencion!,
                            style: const TextStyle(fontSize: 15, height: 1.5),
                          ),
                        ),
                      ],
                      const SizedBox(height: 30),
                      // Opcional: Botón para editar (esto requeriría más lógica y pasar a PantallaEntrevistaSocioeconomica en modo edición)
                      // ElevatedButton(
                      //   onPressed: () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) => PantallaEntrevistaSocioeconomica(
                      //           pacienteId: widget.entrevista.pacienteID,
                      //           // Deberías pasar la entrevista existente para cargarla en modo edición
                      //           // entrevistaAEditar: widget.entrevista, // Necesitarías añadir este parámetro
                      //         ),
                      //       ),
                      //     );
                      //   },
                      //   child: const Text('Modificar Entrevista'),
                      // ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoSeccion(String etiqueta, String valor, {double valorFontSize = 16.0}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        SelectableText(
          valor,
          style: TextStyle(fontSize: valorFontSize, color: Colors.black87),
        ),
      ],
    );
  }
}