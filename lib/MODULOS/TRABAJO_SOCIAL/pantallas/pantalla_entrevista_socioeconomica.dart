// lib/modulos/TRABAJO_SOCIAL/pantallas/pantalla_entrevista_socioeconomica.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para TextInputFormatter
import '../../../modelos_globales/modelo_paciente.dart';
import '../../../modelos_globales/modelo_entrevista_social.dart';
import '../servicios/servicio_bd_trabajo_social.dart';

class PantallaEntrevistaSocioeconomica extends StatefulWidget {
  final int pacienteId;

  const PantallaEntrevistaSocioeconomica({super.key, required this.pacienteId});

  @override
  State<PantallaEntrevistaSocioeconomica> createState() =>
      _PantallaEntrevistaSocioeconomicaState();
}

class _PantallaEntrevistaSocioeconomicaState
    extends State<PantallaEntrevistaSocioeconomica> {
  final _formKey = GlobalKey<FormState>();
  final ServicioBDTrabajoSocial _servicioBD = ServicioBDTrabajoSocial();

  Paciente? _paciente;
  bool _isLoadingPaciente = true;

  // Controladores para cada campo de la entrevista
  final TextEditingController _ingresoMensualController = TextEditingController();
  final TextEditingController _dependientesEconomicosController = TextEditingController();
  bool? _tieneSeguroMedico; // true para Sí, false para No, null sin seleccionar
  final TextEditingController _viviendaController = TextEditingController(); // Opciones: Propia, Rentada, Prestada, Otro
  bool? _tieneMiembrosConDiscapacidad;
  final TextEditingController _descripcionMiembrosDiscapacidadController = TextEditingController();
  bool? _recibeOtroApoyo;
  final TextEditingController _descripcionOtroApoyoController = TextEditingController();
  final TextEditingController _observacionesAdicionalesController = TextEditingController();

  // Controladores y estado para la recomendación de exención (como antes)
  bool _recomiendaExencion = false;
  final TextEditingController _justificacionExencionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDatosPaciente();
    // No pre-llenamos un campo grande, sino que tendremos campos individuales.
  }

  Future<void> _cargarDatosPaciente() async {
    // ... (código de _cargarDatosPaciente igual que antes)
    try {
      final pacienteCargado =
          await _servicioBD.obtenerPacientePorId(widget.pacienteId);
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
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al cargar datos del paciente: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  String _construirContenidoEntrevista() {
    // Construir la cadena de texto a partir de los campos individuales
    return '''
Valoración Socioeconómica:
1. Ingreso mensual hogar: ${_ingresoMensualController.text}
2. Dependientes económicos: ${_dependientesEconomicosController.text}
3. Seguro médico: ${_boolASiNo(_tieneSeguroMedico)}
4. Vivienda: ${_viviendaController.text}
5. Miembros con discapacidad/enf. crónica: ${_boolASiNo(_tieneMiembrosConDiscapacidad)}${_tieneMiembrosConDiscapacidad == true && _descripcionMiembrosDiscapacidadController.text.isNotEmpty ? ' (${_descripcionMiembrosDiscapacidadController.text})' : ''}
6. Otro apoyo: ${_boolASiNo(_recibeOtroApoyo)}${_recibeOtroApoyo == true && _descripcionOtroApoyoController.text.isNotEmpty ? ' (${_descripcionOtroApoyoController.text})' : ''}

Observaciones adicionales: ${_observacionesAdicionalesController.text}
''';
  }

  String _boolASiNo(bool? valor) {
    if (valor == null) return '[NO ESPECIFICADO]';
    return valor ? 'Sí' : 'No';
  }

  Future<void> _guardarEntrevista() async {
    if (_formKey.currentState!.validate()) {
      final contenidoFinalEntrevista = _construirContenidoEntrevista();

      final nuevaEntrevista = EntrevistaSocial(
        pacienteID: widget.pacienteId,
        fechaEntrevista: DateTime.now().toUtc(),
        contenidoEntrevista: contenidoFinalEntrevista, // Guardamos la cadena construida
        recomiendaExencion: _recomiendaExencion,
        justificacionExencion: _recomiendaExencion
            ? _justificacionExencionController.text
            : null,
      );

      // ... (lógica de guardado con try-catch y SnackBar igual que antes)
       try {
        await _servicioBD.guardarEntrevistaSocial(nuevaEntrevista);
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Entrevista guardada exitosamente'),
                backgroundColor: Colors.green),
            );
            Navigator.of(context).pop(true); // Devuelve true para indicar éxito
        }
      } catch (e) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error al guardar la entrevista: $e'),
                backgroundColor: Colors.red),
            );
        }
      }
    }
  }

  @override
  void dispose() {
    _ingresoMensualController.dispose();
    _dependientesEconomicosController.dispose();
    _viviendaController.dispose();
    _descripcionMiembrosDiscapacidadController.dispose();
    _descripcionOtroApoyoController.dispose();
    _observacionesAdicionalesController.dispose();
    _justificacionExencionController.dispose();
    super.dispose();
  }

  Widget _buildDropdownBool({
      required String etiqueta,
      required bool? valorActual,
      required ValueChanged<bool?> onChanged,
    }) {
    return DropdownButtonFormField<bool>(
      decoration: InputDecoration(
        labelText: etiqueta,
        border: const OutlineInputBorder(),
      ),
      value: valorActual,
      hint: const Text('Seleccione una opción'),
      items: const [
        DropdownMenuItem<bool>(value: true, child: Text('Sí')),
        DropdownMenuItem<bool>(value: false, child: Text('No')),
      ],
      onChanged: onChanged,
      validator: (value) {
        if (value == null) {
          return 'Por favor, seleccione una opción.';
        }
        return null;
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Entrevista Socioeconómica${_paciente != null ? " - ${_paciente!.nombreCompleto}" : ""}'),
      ),
      body: _isLoadingPaciente
          ? const Center(child: CircularProgressIndicator())
          : _paciente == null
              ? const Center(
                  child: Text('No se pudieron cargar los datos del paciente.'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: <Widget>[
                        Text('Paciente: ${_paciente!.nombreCompleto}', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text('ID Paciente: ${widget.pacienteId}'),
                        const SizedBox(height: 20),
                        
                        Text("Valoración Socioeconómica:", style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 10),

                        // 1. Ingreso mensual hogar
                        TextFormField(
                          controller: _ingresoMensualController,
                          decoration: const InputDecoration(labelText: '1. Ingreso mensual hogar', border: OutlineInputBorder(), prefixText: '\$ '),
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                          validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
                        ),
                        const SizedBox(height: 12),

                        // 2. Dependientes económicos
                        TextFormField(
                          controller: _dependientesEconomicosController,
                          decoration: const InputDecoration(labelText: '2. Dependientes económicos', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                           validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
                        ),
                        const SizedBox(height: 12),

                        // 3. Seguro médico
                        _buildDropdownBool(
                          etiqueta: '3. ¿Cuenta con seguro médico?',
                          valorActual: _tieneSeguroMedico,
                          onChanged: (value) => setState(() => _tieneSeguroMedico = value),
                        ),
                        const SizedBox(height: 12),
                        
                        // 4. Vivienda
                        TextFormField(
                          controller: _viviendaController,
                          decoration: const InputDecoration(labelText: '4. Vivienda (Propia, Rentada, Prestada, Otro)', border: OutlineInputBorder()),
                          validator: (value) => (value == null || value.isEmpty) ? 'Campo requerido' : null,
                        ),
                        const SizedBox(height: 12),

                        // 5. Miembros con discapacidad/enf. crónica
                        _buildDropdownBool(
                          etiqueta: '5. ¿Miembros con discapacidad/enf. crónica con gastos?',
                          valorActual: _tieneMiembrosConDiscapacidad,
                          onChanged: (value) => setState(() => _tieneMiembrosConDiscapacidad = value),
                        ),
                        if (_tieneMiembrosConDiscapacidad == true) ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _descripcionMiembrosDiscapacidadController,
                            decoration: const InputDecoration(labelText: 'Descripción (discapacidad/enf. crónica)', border: OutlineInputBorder()),
                            maxLines: 2,
                          ),
                        ],
                        const SizedBox(height: 12),

                        // 6. Otro apoyo
                         _buildDropdownBool(
                          etiqueta: '6. ¿Recibe algún otro tipo de apoyo?',
                          valorActual: _recibeOtroApoyo,
                          onChanged: (value) => setState(() => _recibeOtroApoyo = value),
                        ),
                        if (_recibeOtroApoyo == true) ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _descripcionOtroApoyoController,
                            decoration: const InputDecoration(labelText: 'Especificar otro apoyo', border: OutlineInputBorder()),
                             maxLines: 2,
                          ),
                        ],
                        const SizedBox(height: 12),

                        // Observaciones adicionales
                        TextFormField(
                          controller: _observacionesAdicionalesController,
                          decoration: const InputDecoration(labelText: 'Observaciones adicionales', border: OutlineInputBorder()),
                          maxLines: 4,
                        ),
                        const SizedBox(height: 20),
                        
                        // Recomendación de Exención (como antes)
                        SwitchListTile(
                          title: const Text('¿Recomienda Exención de Pago?'),
                          value: _recomiendaExencion,
                          onChanged: (bool value) => setState(() => _recomiendaExencion = value),
                        ),
                        if (_recomiendaExencion) ...[
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _justificacionExencionController,
                            decoration: const InputDecoration(labelText: 'Justificación para la Exención', border: OutlineInputBorder()),
                            maxLines: 3,
                            validator: (value) => (_recomiendaExencion && (value == null || value.isEmpty)) ? 'Justificación requerida' : null,
                          ),
                        ],
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: _guardarEntrevista,
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16.0)),
                          child: const Text('Guardar Entrevista'),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}