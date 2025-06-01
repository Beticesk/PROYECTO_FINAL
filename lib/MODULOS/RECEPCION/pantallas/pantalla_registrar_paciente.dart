// lib/modulos/recepcion/pantallas/pantalla_registrar_paciente.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para TextInputFormatter
// Asegúrate que las rutas de importación sean correctas
import '../../../modelos_globales/modelo_paciente.dart';
import '../servicios/servicio_bd_recepcion.dart';

class PantallaRegistrarPaciente extends StatefulWidget {
  const PantallaRegistrarPaciente({super.key});

  @override
  State<PantallaRegistrarPaciente> createState() => _PantallaRegistrarPacienteState();
}

class _PantallaRegistrarPacienteState extends State<PantallaRegistrarPaciente> {
  final _formKey = GlobalKey<FormState>();
  final ServicioBDRecepcion _servicioBD = ServicioBDRecepcion();

  // Controladores para los campos de texto
  final TextEditingController _nombreCompletoController = TextEditingController();
  final TextEditingController _contactoTelefonoController = TextEditingController();
  final TextEditingController _contactoEmailController = TextEditingController();
  final TextEditingController _idiomaController = TextEditingController();

  // Variables para los campos de fecha y booleanos
  DateTime? _fechaNacimiento;
  DateTime? _fechaInicioTratamiento;
  bool _documentacionIncompleta = false;
  bool _solicitaCertificadoDiscapacidad = false;

  bool _isLoading = false;

  @override
  void dispose() {
    _nombreCompletoController.dispose();
    _contactoTelefonoController.dispose();
    _contactoEmailController.dispose();
    _idiomaController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha(BuildContext context, bool esFechaNacimiento) async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: esFechaNacimiento ? (_fechaNacimiento ?? DateTime(DateTime.now().year - 18)) : (_fechaInicioTratamiento ?? DateTime.now()),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: esFechaNacimiento ? 'Seleccione Fecha de Nacimiento' : 'Seleccione Fecha de Inicio de Tratamiento',
    );
    if (fechaSeleccionada != null) {
      setState(() {
        if (esFechaNacimiento) {
          _fechaNacimiento = fechaSeleccionada;
        } else {
          _fechaInicioTratamiento = fechaSeleccionada;
        }
      });
    }
  }

  Future<void> _guardarPaciente() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final nuevoPaciente = Paciente(
        nombreCompleto: _nombreCompletoController.text.trim(),
        fechaNacimiento: _fechaNacimiento,
        contactoTelefono: _contactoTelefonoController.text.trim(),
        contactoEmail: _contactoEmailController.text.trim().isEmpty ? null : _contactoEmailController.text.trim(),
        idioma: _idiomaController.text.trim().isEmpty ? null : _idiomaController.text.trim(),
        documentacionIncompleta: _documentacionIncompleta,
        certificadoDiscapacidadSol: _solicitaCertificadoDiscapacidad,
        // fechaRegistroSistema se asignará por defecto en la BD o al crear el objeto si es necesario
        fechaInicioTratamientoGeneral: _fechaInicioTratamiento,
        // pacienteID será null y se autogenerará en la BD
        // certificadoDiscapacidadEntreg y fechaFinTratamientoGeneral por defecto o se asignan después
      );

      try {
        final nuevoId = await _servicioBD.registrarNuevoPaciente(nuevoPaciente);
        if (mounted) {
          if (nuevoId != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Paciente "${nuevoPaciente.nombreCompleto}" registrado con ID: $nuevoId'),
                  backgroundColor: Colors.green),
            );
            _formKey.currentState?.reset(); // Limpia el formulario
            _nombreCompletoController.clear();
            _contactoTelefonoController.clear();
            _contactoEmailController.clear();
            _idiomaController.clear();
            setState(() { // Resetea los campos de estado
              _fechaNacimiento = null;
              _fechaInicioTratamiento = null;
              _documentacionIncompleta = false;
              _solicitaCertificadoDiscapacidad = false;
            });
            // Opcional: Navigator.pop(context); // Regresar a la pantalla anterior
          } else {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Paciente registrado, pero no se pudo obtener el ID.'),
                  backgroundColor: Colors.orange),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error al registrar paciente: $e'),
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

  String _formatearFechaParaMostrar(DateTime? fecha) {
    if (fecha == null) return 'No seleccionada';
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Nuevo Paciente'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _nombreCompletoController,
                decoration: const InputDecoration(labelText: 'Nombre Completo', border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, ingrese el nombre completo.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text('Fecha de Nacimiento: ${_formatearFechaParaMostrar(_fechaNacimiento)}'),
                  ),
                  ElevatedButton(
                    onPressed: () => _seleccionarFecha(context, true),
                    child: const Text('Seleccionar'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactoTelefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono de Contacto', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactoEmailController,
                decoration: const InputDecoration(labelText: 'Email (Opcional)', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _idiomaController,
                decoration: const InputDecoration(labelText: 'Idioma (Opcional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('¿Documentación Incompleta?'),
                value: _documentacionIncompleta,
                onChanged: (bool value) {
                  setState(() {
                    _documentacionIncompleta = value;
                  });
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text('¿Solicita Certificado de Discapacidad?'),
                value: _solicitaCertificadoDiscapacidad,
                onChanged: (bool value) {
                  setState(() {
                    _solicitaCertificadoDiscapacidad = value;
                  });
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text('Inicio Tratamiento (Opcional): ${_formatearFechaParaMostrar(_fechaInicioTratamiento)}'),
                  ),
                  ElevatedButton(
                    onPressed: () => _seleccionarFecha(context, false),
                    child: const Text('Seleccionar'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar Paciente'),
                      onPressed: _guardarPaciente,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        // primary: Theme.of(context).colorScheme.primary, // Color primario para el botón
                        // onPrimary: Theme.of(context).colorScheme.onPrimary, // Color del texto e icono en el botón
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}