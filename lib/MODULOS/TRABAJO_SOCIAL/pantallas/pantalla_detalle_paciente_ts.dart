// lib/modulos/TRABAJO_SOCIAL/pantallas/pantalla_detalle_paciente_ts.dart
import 'package:flutter/material.dart';
// Asegúrate que las rutas de importación sean correctas
import '../../../modelos_globales/modelo_paciente.dart';
import '../servicios/servicio_bd_trabajo_social.dart';
import './pantalla_entrevista_socioeconomica.dart'; // Para la navegación

import '../../../modelos_globales/modelo_entrevista_social.dart'; // Para usar EntrevistaSocial
import './pantalla_ver_entrevista_solo_lectura.dart'; // Para navegar si ya existe entrevista

class PantallaDetallePacienteTS extends StatefulWidget {
  final int pacienteId;

  const PantallaDetallePacienteTS({super.key, required this.pacienteId});

  @override
  State<PantallaDetallePacienteTS> createState() => _PantallaDetallePacienteTSState();
}

class _PantallaDetallePacienteTSState extends State<PantallaDetallePacienteTS> {
  final ServicioBDTrabajoSocial _servicioBD = ServicioBDTrabajoSocial();
  Paciente? _paciente;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatosPaciente();
  }

  Future<void> _cargarDatosPaciente() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final pacienteCargado = await _servicioBD.obtenerPacientePorId(widget.pacienteId);
      if (mounted) {
        setState(() {
          _paciente = pacienteCargado;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error al cargar datos del paciente: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_error!), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _navegarARegistroEntrevista() async { // Convertido a async
    if (_paciente == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos del paciente no cargados.'), backgroundColor: Colors.orange),
      );
      return;
    }

    // Muestra un indicador de carga mientras se verifica la entrevista
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      // AQUÍ ES DONDE SE LLAMA A LA FUNCIÓN CORRECTA PARA VERIFICAR:
      final EntrevistaSocial? entrevistaExistente = await _servicioBD.obtenerEntrevistaMasReciente(widget.pacienteId);
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop(); // Cierra el diálogo de carga

      if (mounted) { // Verifica si el widget sigue montado
        if (entrevistaExistente != null) {
          // YA EXISTE: Navegar a la pantalla de solo lectura
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PantallaVerEntrevistaSoloLectura(entrevista: entrevistaExistente),
            ),
          );
        } else {
          // NO EXISTE: Navegar a la pantalla de creación
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PantallaEntrevistaSocioeconomica(pacienteId: widget.pacienteId),
            ),
          ).then((seGuardoNuevaEntrevista) {
            // Si la pantalla de entrevista devuelve true (porque se guardó exitosamente),
            // podrías querer recargar los datos en esta pantalla de detalle para reflejarlo.
            if (seGuardoNuevaEntrevista == true && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('Nueva entrevista registrada.'), backgroundColor: Colors.blue),
              );
              // Opcional: Aquí podrías llamar a una función para recargar la lista de entrevistas
              // si la estuvieras mostrando en esta pantalla de detalle.
              // Por ejemplo: _cargarDatosEntrevistasDelPaciente();
            }
          });
        }
      }
    } catch (e) {
      if (mounted) { // Verifica antes de usar context después de un await
         Navigator.of(context).pop(); // Cierra el diálogo de carga en caso de error
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error al verificar entrevista: $e'), backgroundColor: Colors.red),
         );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_paciente?.nombreCompleto ?? 'Detalle del Paciente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatosPaciente, // Botón para recargar
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('Error: $_error', style: const TextStyle(color: Colors.red))))
              : _paciente == null
                  ? const Center(child: Text('No se encontró información del paciente.'))
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: RefreshIndicator( // Para recargar con swipe down
                        onRefresh: _cargarDatosPaciente,
                        child: ListView(
                          children: <Widget>[
                            _buildInfoPaciente('ID Paciente:', widget.pacienteId.toString()),
                            _buildInfoPaciente('Nombre Completo:', _paciente!.nombreCompleto),
                            _buildInfoPaciente('Fecha de Nacimiento:', _paciente!.fechaNacimiento?.toLocal().toString().split(' ')[0] ?? "N/A"),
                            _buildInfoPaciente('Teléfono:', _paciente!.contactoTelefono ?? "N/A"),
                            _buildInfoPaciente('Email:', _paciente!.contactoEmail ?? "N/A"),
                            _buildInfoPaciente('Idioma:', _paciente!.idioma ?? "N/A"),
                            SwitchListTile(
                              title: const Text('Documentación Incompleta'),
                              value: _paciente!.documentacionIncompleta,
                              onChanged: null, // Solo lectura para este ejemplo, o implementa edición
                                dense: true,
                            ),
                            SwitchListTile(
                              title: const Text('Solicitó Certificado Discap.'),
                              value: _paciente!.certificadoDiscapacidadSol,
                              onChanged: null,
                              dense: true,
                            ),
                             SwitchListTile(
                              title: const Text('Certificado Discap. Entregado'),
                              value: _paciente!.certificadoDiscapacidadEntreg,
                              onChanged: null,
                              dense: true,
                            ),
                            _buildInfoPaciente('Inicio Tratamiento:', _paciente!.fechaInicioTratamientoGeneral?.toLocal().toString().split(' ')[0] ?? "N/A"),
                            _buildInfoPaciente('Fin Tratamiento:', _paciente!.fechaFinTratamientoGeneral?.toLocal().toString().split(' ')[0] ?? "N/A"),
                            
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.assignment_ind),
                              onPressed: _navegarARegistroEntrevista,
                              label: const Text('Registrar/Ver Entrevista Socioeconómica'),
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12.0)),
                            ),
                            // Aquí podrías añadir en el futuro:
                            // - Lista de entrevistas sociales anteriores para este paciente.
                            // - Historial de citas.
                            // - Historial de pagos.
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildInfoPaciente(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$etiqueta ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(valor)),
        ],
      ),
    );
  }
}