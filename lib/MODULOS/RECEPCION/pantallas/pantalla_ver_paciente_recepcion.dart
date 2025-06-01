// lib/modulos/recepcion/pantallas/pantalla_ver_paciente_recepcion.dart
import 'package:flutter/material.dart';
import '../../../modelos_globales/modelo_paciente.dart';
import '../../../modelos_globales/modelo_entrevista_social.dart'; 
import '../servicios/servicio_bd_recepcion.dart';
import './pantalla_agendar_cita_recepcion.dart';
import '../../../modelos_globales/modelo_cita.dart';
import './pantalla_registrar_pago_recepcion.dart';

class PantallaVerPacienteRecepcion extends StatefulWidget {
  final int pacienteId;

  const PantallaVerPacienteRecepcion({super.key, required this.pacienteId});

  @override
  State<PantallaVerPacienteRecepcion> createState() =>
      _PantallaVerPacienteRecepcionState();
}

class _PantallaVerPacienteRecepcionState extends State<PantallaVerPacienteRecepcion> {
  final ServicioBDRecepcion _servicioBD = ServicioBDRecepcion();
  List<Cita>? _citasPendientes;
  Paciente? _paciente;
  EntrevistaSocial? _entrevista; // Para almacenar la entrevista cargada
  bool _isLoadingPaciente = true;
  bool _isLoadingEntrevista = true; // Estado de carga para la entrevista
  String? _errorCarga;

  @override
  void initState() {
    super.initState();
    _cargarTodosLosDatos();
  }

  Future<void> _cargarTodosLosDatos() async {
    setState(() {
      _isLoadingPaciente = true;
      _isLoadingEntrevista = true; // Inicia la carga de la entrevista también
      _errorCarga = null;
    });
    try {
      // Cargar datos del paciente
      final pacienteCargado = await _servicioBD.obtenerPacientePorId(widget.pacienteId);
      if (mounted) {
        setState(() {
          _paciente = pacienteCargado;
          _isLoadingPaciente = false;
        });
      }

      // Cargar datos de la entrevista (si existe) DESPUÉS de cargar el paciente
      if (_paciente != null && mounted) { 
        final entrevistaCargada = await _servicioBD.obtenerEntrevistaDelPaciente(widget.pacienteId);
        if (mounted) {
          setState(() {
            _entrevista = entrevistaCargada;
            _isLoadingEntrevista = false;
          });
        }
      } else if (mounted) { 
        // Si no hay paciente, o el widget ya no está montado, marcamos la carga de entrevista como finalizada.
        setState(() => _isLoadingEntrevista = false);
      }


     // Cargar citas pendientes
        final citasCargadas = await _servicioBD.obtenerCitasPendientesDelPaciente(widget.pacienteId); // <--- USA EL MÉTODO DEL SERVICIO
        if (mounted) {
          setState(() { _citasPendientes = citasCargadas; }); // <--- ASIGNA A LA VARIABLE DE ESTADO
        }
       else if (mounted) {
        setState(() { _isLoadingEntrevista = false; });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPaciente = false;
          _isLoadingEntrevista = false;
          _errorCarga = 'Error al cargar datos: $e';
        });
      }
    }
  }

  String _formatearFecha(DateTime? fecha, {bool incluirHora = false}) {
    if (fecha == null) return "N/A";
    String fechaFormateada =
        '${fecha.toLocal().day.toString().padLeft(2, '0')}/${fecha.toLocal().month.toString().padLeft(2, '0')}/${fecha.toLocal().year}';
    if (incluirHora) {
      fechaFormateada += ' ${fecha.toLocal().hour.toString().padLeft(2, '0')}:${fecha.toLocal().minute.toString().padLeft(2, '0')}';
    }
    return fechaFormateada;
  }

void _procederAAgendarCita() { // <--- CORREGIDO: 'id' cambiado a 'void'
  // Esta función contiene la lógica original de navegación
  if (_paciente != null) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PantallaAgendarCitaRecepcion(paciente: _paciente!),
      ),
    ).then((citaAgendadaConExito) {
      if (citaAgendadaConExito == true && mounted) {
        _cargarTodosLosDatos(); // Recargar todo para ver la nueva cita y actualizar listas
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Cita agendada. Lista actualizada.'),
              duration: Duration(seconds: 3)),
        );
      }
    });
  }
}

  Future<void> _navegarAAgendarCita() async { // Convertido a async para el diálogo
    if (_paciente == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos del paciente no cargados.'), backgroundColor: Colors.orange),
      );
      return;
    }

    // Verificar si hay citas pendientes cargadas
    if (_citasPendientes != null && _citasPendientes!.isNotEmpty) {
      // Formatear las primeras citas para mostrar en el diálogo (ej. las primeras 3)
      String citasExistentesStr = _citasPendientes!
          .take(3) // Tomar un máximo de 3 para no hacer el diálogo muy largo
          .map((cita) =>
              '- ${_formatearFecha(cita.fechaHoraCita, incluirHora: true)} (${cita.tipoConsulta ?? "N/A"})')
          .join('\n');
      if (_citasPendientes!.length > 3) {
          citasExistentesStr += "\n- ... y más.";
      }

      // Mostrar diálogo de confirmación
      final bool? confirmarAgendarOtra = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Paciente con Citas Existentes'),
            content: SingleChildScrollView( // Por si la lista de citas es larga
              child: ListBody(
                children: <Widget>[
                  const Text('Este paciente ya tiene la(s) siguiente(s) cita(s) programada(s):'),
                  const SizedBox(height: 8),
                  Text(citasExistentesStr),
                  const SizedBox(height: 16),
                  const Text('¿Está seguro de que desea agendar una cita adicional?'),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () {
                  Navigator.of(dialogContext).pop(false); // No agendar
                },
              ),
              ElevatedButton(
                child: const Text('Sí, Agendar Otra'),
                onPressed: () {
                  Navigator.of(dialogContext).pop(true); // Sí, proceder a agendar
                },
              ),
            ],
          );
        },
      );

      if (confirmarAgendarOtra == true) {
        _procederAAgendarCita(); // Llama a la función que realmente navega
      }
      // Si es false o null (diálogo cerrado), no hace nada.
    } else {
      // No hay citas pendientes, proceder a agendar directamente
      _procederAAgendarCita();
    }
  }

void _navegarARegistrarPago() {
    if (_paciente == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos del paciente no cargados.'), backgroundColor: Colors.orange),
      );
      return;
    }

    // Verificar si la entrevista ha sido cargada y si existe
    // _isLoadingEntrevista debe ser false para asegurar que el intento de carga ya ocurrió.
    if (!_isLoadingEntrevista && _entrevista == null) {
      // No hay entrevista registrada para este paciente
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Entrevista No Realizada'),
            content: const Text('Este paciente aún no tiene una entrevista socioeconómica registrada. No se puede proceder con el registro de pago o exención hasta que Trabajo Social complete la entrevista.'),
            actions: <Widget>[
              TextButton(
                child: const Text('Entendido'),
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Cierra el AlertDialog
                },
              ),
            ],
          );
        },
      );
    } else if (_entrevista != null) {
      // Sí hay una entrevista, proceder a la pantalla de registrar pago/exención
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PantallaRegistrarPagoRecepcion(paciente: _paciente!),
        ),
      ).then((registroExitoso) {
        if (registroExitoso == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Operación de pago/exención procesada.'))
          );
          _cargarTodosLosDatos(); // Vuelve a cargar los datos para reflejar cualquier cambio
        }
      });
    } else if (_isLoadingEntrevista) {
        // Aún se está cargando la información de la entrevista
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cargando información de entrevista, intente en un momento...'))
        );
    }
  }
  
  void _navegarAEditarPaciente() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navegar a editar paciente ID: ${widget.pacienteId} (Pendiente)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Un solo indicador de carga general hasta que ambos (paciente y entrevista) hayan intentado cargarse.
    bool loadingGeneral = _isLoadingPaciente || _isLoadingEntrevista;

    return Scaffold(
      appBar: AppBar(
        title: Text(_paciente?.nombreCompleto ?? 'Detalle del Paciente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: 'Editar Paciente (Funcionalidad Pendiente)',
            onPressed: _paciente != null ? _navegarAEditarPaciente : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarTodosLosDatos,
          ),
        ],
      ),
      body: loadingGeneral
          ? const Center(child: CircularProgressIndicator())
          : _errorCarga != null
              ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_errorCarga!, style: const TextStyle(color: Colors.red))))
              : _paciente == null
                  ? const Center(child: Text('No se encontró información del paciente.'))
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ListView(
                        children: <Widget>[
                          // --- Sección de Datos del Paciente ---
                          Text("Datos del Paciente:", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
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
                          
                          const SizedBox(height: 20),
                          const Divider(thickness: 1),
                          // --- Sección de Entrevista Socioeconómica ---
                          _buildSeccionEntrevista(), // Widget que muestra la info de la entrevista
                          const SizedBox(height: 20),
                          const Divider(thickness: 1),

                          // --- Sección de Acciones de Recepción ---
                          const SizedBox(height: 12),
                          Text("Acciones de Recepción:", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.calendar_month),
                            label: const Text('Agendar Nueva Cita'),
                            onPressed: _paciente != null ? _navegarAAgendarCita : null,
                            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.payment),
                            label: const Text('Registrar Pago / Exención'),
                            onPressed: _paciente != null ? _navegarARegistrarPago : null,
                            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildInfoFila(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0), // Reducido el padding vertical
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$etiqueta ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), // Tamaño de fuente ajustado
          Expanded(child: SelectableText(valor, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildInfoFilaBool(String etiqueta, bool valor) {
     return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0), // Reducido el padding vertical
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$etiqueta ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), // Tamaño de fuente ajustado
          Expanded(child: Text(valor ? 'Sí' : 'No', style: TextStyle(fontSize: 14, color: valor ? Colors.green.shade700 : Colors.red.shade700))),
        ],
      ),
    );
  }

  Widget _buildSeccionEntrevista() {
    // No necesitamos _isLoadingEntrevista aquí porque loadingGeneral ya lo maneja antes de llamar a este widget.
    // Si llegamos aquí, _isLoadingEntrevista ya debería ser false.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text("Entrevista Socioeconómica:", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _entrevista == null
            ? Card(
                color: Colors.amber[50], // Un color suave para el mensaje
                elevation: 0,
                shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.amber.shade300),
                    borderRadius: BorderRadius.circular(4)
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber.shade800, size: 28),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('Este paciente aún no tiene una entrevista socioeconómica registrada.', style: TextStyle(fontSize: 15))),
                    ],
                  ),
                ),
              )
            : Card(
                elevation: 1.0,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoFila('Fecha de Entrevista:', _formatearFecha(_entrevista!.fechaEntrevista, incluirHora: true)),
                      const SizedBox(height: 8),
                      _buildInfoFila('Recomienda Exención:', _entrevista!.recomiendaExencion ? 'Sí' : 'No'),
                      if (_entrevista!.recomiendaExencion && _entrevista!.justificacionExencion != null && _entrevista!.justificacionExencion!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildInfoFila('Justificación:', _entrevista!.justificacionExencion!),
                      ],
                      const SizedBox(height: 10),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('Ver Contenido Completo', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                        childrenPadding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                        children: [
                           Container(
                              padding: const EdgeInsets.all(10.0),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: SelectableText(
                                _entrevista!.contenidoEntrevista,
                                style: const TextStyle(fontSize: 13, height: 1.4),
                              ),
                            ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
      ],
    );
  }
}