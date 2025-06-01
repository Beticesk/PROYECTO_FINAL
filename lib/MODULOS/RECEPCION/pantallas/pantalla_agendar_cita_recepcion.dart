// lib/modulos/recepcion/pantallas/pantalla_agendar_cita_recepcion.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import '../../../modelos_globales/modelo_cita.dart'; // <--- IMPORTANTE: AÑADE O VERIFICA ESTA LÍNEA
import '../../../modelos_globales/modelo_paciente.dart'; 
import '../servicios/servicio_bd_recepcion.dart';

class PantallaAgendarCitaRecepcion extends StatefulWidget {
  final Paciente paciente; // Recibe el objeto Paciente completo

  const PantallaAgendarCitaRecepcion({super.key, required this.paciente});

  @override
  State<PantallaAgendarCitaRecepcion> createState() =>
      _PantallaAgendarCitaRecepcionState();
}

class _PantallaAgendarCitaRecepcionState extends State<PantallaAgendarCitaRecepcion> {
  final _formKey = GlobalKey<FormState>();
  final ServicioBDRecepcion _servicioBD = ServicioBDRecepcion();

  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;
  String? _tipoConsultaSeleccionado;

  bool _isLoading = false;

  // Opciones para el tipo de consulta. Estas podrían venir de una base de datos en el futuro.
  // Basado en el PDF: "Clasificación por área: terapia física, lenguaje, psicología" [cite: 20]
  // y también se mencionan "Consulta médica" y "Entrevista Inicial TS".
  final List<String> _opcionesTipoConsulta = [
    'Consulta Médica',
    'Terapia Física',
    'Terapia de Lenguaje',
    'Psicología',
    'Valoración Discapacidad',
    'Entrevista Inicial TS', // Si Recepción también agenda esto
    'Otro'
  ];

  @override
  void initState() {
    super.initState();
    // Inicializar fecha y hora con valores por defecto (ej. mañana a una hora específica)
    _fechaSeleccionada = DateTime.now().add(const Duration(days: 1));
    _horaSeleccionada = const TimeOfDay(hour: 9, minute: 0);
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? fechaElegida = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime.now(), // No permitir fechas pasadas
      lastDate: DateTime.now().add(const Duration(days: 365)), // Permitir agendar hasta un año
      locale: const Locale('es', 'ES'), // Para asegurar el idioma español
    );
    if (fechaElegida != null && fechaElegida != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = fechaElegida;
      });
    }
  }

  Future<void> _seleccionarHora(BuildContext context) async {
    final TimeOfDay? horaElegida = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada ?? TimeOfDay.now(),
      // El locale para showTimePicker se toma del MaterialApp
    );
    if (horaElegida != null && horaElegida != _horaSeleccionada) {
      setState(() {
        _horaSeleccionada = horaElegida;
      });
    }
  }

  Future<void> _agendarCita() async {
    if (_formKey.currentState!.validate()) {
      if (_fechaSeleccionada == null || _horaSeleccionada == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, seleccione fecha y hora.'), backgroundColor: Colors.orange),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Combinar fecha y hora
      final DateTime fechaHoraCitaCompleta = DateTime(
        _fechaSeleccionada!.year,
        _fechaSeleccionada!.month,
        _fechaSeleccionada!.day,
        _horaSeleccionada!.hour,
        _horaSeleccionada!.minute,
      );

      final nuevaCita = Cita(
        pacienteID: widget.paciente.pacienteID!, // Asumimos que pacienteID no es nulo aquí
        fechaHoraCita: fechaHoraCitaCompleta,
        tipoConsulta: _tipoConsultaSeleccionado,
        estadoCita: 'Programada', // Estado inicial
        profesionalAsignado: null, // Lo dejaremos null por ahora
      );

      try {
        await _servicioBD.agendarNuevaCita(nuevaCita);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Cita agendada exitosamente.'),
                backgroundColor: Colors.green),
          );
          Navigator.of(context).pop(true); // Devuelve true para indicar éxito
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error al agendar la cita: $e'),
                backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Formateador para mostrar fecha y hora
    final formatoFecha = DateFormat('dd/MM/yyyy', 'es_ES');
    final formatoHora = DateFormat('HH:mm', 'es_ES'); // O usa h:mm a

    return Scaffold(
      appBar: AppBar(
        title: Text('Agendar Cita para ${widget.paciente.nombreCompleto}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              Text('Paciente: ${widget.paciente.nombreCompleto}', style: Theme.of(context).textTheme.titleMedium),
              Text('ID: ${widget.paciente.pacienteID}'),
              const SizedBox(height: 20),

              // Selector de Fecha
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Fecha de la Cita'),
                subtitle: Text(_fechaSeleccionada == null
                    ? 'No seleccionada'
                    : formatoFecha.format(_fechaSeleccionada!)),
                onTap: () => _seleccionarFecha(context),
                trailing: const Icon(Icons.arrow_drop_down),
              ),
              const Divider(),

              // Selector de Hora
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Hora de la Cita'),
                subtitle: Text(_horaSeleccionada == null
                    ? 'No seleccionada'
                    : _horaSeleccionada!.format(context)), // Usa format del TimeOfDay
                onTap: () => _seleccionarHora(context),
                trailing: const Icon(Icons.arrow_drop_down),
              ),
              const Divider(),
              const SizedBox(height: 12),

              // Selector de Tipo de Consulta
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Tipo de Consulta',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medical_services_outlined)
                ),
                value: _tipoConsultaSeleccionado,
                hint: const Text('Seleccione el tipo de consulta'),
                isExpanded: true,
                items: _opcionesTipoConsulta.map((String valor) {
                  return DropdownMenuItem<String>(
                    value: valor,
                    child: Text(valor),
                  );
                }).toList(),
                onChanged: (String? nuevoValor) {
                  setState(() {
                    _tipoConsultaSeleccionado = nuevoValor;
                  });
                },
                validator: (value) =>
                    value == null ? 'Seleccione un tipo de consulta' : null,
              ),
              const SizedBox(height: 30),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.save_as),
                      label: const Text('Agendar Cita'),
                      onPressed: _agendarCita,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}