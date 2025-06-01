// lib/modulos/recepcion/pantallas/pantalla_registrar_pago_recepcion.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Asegúrate que las rutas de importación sean correctas
import '../../../modelos_globales/modelo_paciente.dart';
import '../../../modelos_globales/modelo_pago.dart';
import '../../../modelos_globales/modelo_entrevista_social.dart';
import '../servicios/servicio_bd_recepcion.dart';

class PantallaRegistrarPagoRecepcion extends StatefulWidget {
  final Paciente paciente; // Recibe el objeto Paciente

  const PantallaRegistrarPagoRecepcion({super.key, required this.paciente});

  @override
  State<PantallaRegistrarPagoRecepcion> createState() =>
      _PantallaRegistrarPagoRecepcionState();
}

class _PantallaRegistrarPagoRecepcionState extends State<PantallaRegistrarPagoRecepcion> {
  final _formKey = GlobalKey<FormState>();
  final ServicioBDRecepcion _servicioBD = ServicioBDRecepcion();

  EntrevistaSocial? _entrevistaDelPaciente;
  bool _isLoadingEntrevista = true;

  // Controladores y variables de estado para el formulario de pago
  String? _conceptoSeleccionado;
  final TextEditingController _montoController = TextEditingController();
  String? _estadoPagoSeleccionado; // 'Pagado', 'Exento', 'Pendiente'
  final TextEditingController _notasExencionController = TextEditingController();
  // int? _citaIdAsociada; // Opcional: si el pago se liga a una cita específica

  bool _isLoadingGuardado = false;

  // Definición de conceptos y costos [cite: 2]
  final Map<String, double> _costosConceptos = {
    'Consulta Médica': 150.00,
    'Certificado Discapacidad': 150.00, // Costo adicional [cite: 2]
    'Ambos (Consulta + Certificado)': 300.00, // Si solo acude por certificado, paga ambos [cite: 3]
    'Otro': 0.00, // Para montos manuales
  };

  final List<String> _opcionesEstadoPago = ['Pagado', 'Exento', 'Pendiente'];

  @override
  void initState() {
    super.initState();
    _cargarEntrevistaPaciente();
    _estadoPagoSeleccionado = 'Pagado'; // Valor por defecto
  }

  Future<void> _cargarEntrevistaPaciente() async {
    setState(() => _isLoadingEntrevista = true);
    try {
      _entrevistaDelPaciente = await _servicioBD.obtenerEntrevistaDelPaciente(widget.paciente.pacienteID!);
      if (_entrevistaDelPaciente?.recomiendaExencion == true) {
        // Si TS recomienda exención, preseleccionar 'Exento' y copiar justificación
        setState(() {
          _estadoPagoSeleccionado = 'Exento';
          _notasExencionController.text = _entrevistaDelPaciente?.justificacionExencion ?? '';
          if (_conceptoSeleccionado != null && _costosConceptos.containsKey(_conceptoSeleccionado)) {
            // Si es exento, el monto a efectos de registro podría ser el costo del servicio pero marcado como exento
            // o 0. Por ahora, mantenemos el costo del servicio para el registro.
            _montoController.text = _costosConceptos[_conceptoSeleccionado!]!.toStringAsFixed(2);
          }
        });
      }
    } catch (e) {
      // No es crítico si no se carga la entrevista, pero se puede mostrar un mensaje
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Aviso: No se pudo cargar información de entrevista socioeconómica: $e'), backgroundColor: Colors.orange));
    } finally {
      if (mounted) setState(() => _isLoadingEntrevista = false);
    }
  }
  
  void _actualizarMontoPorConcepto(String? concepto) {
    setState(() {
      _conceptoSeleccionado = concepto;
      if (concepto != null && _costosConceptos.containsKey(concepto) && concepto != 'Otro') {
        _montoController.text = _costosConceptos[concepto]!.toStringAsFixed(2);
      } else if (concepto == 'Otro') {
         _montoController.text = ''; // Limpiar para entrada manual
      }
    });
  }

  Future<void> _registrarPago() async {
    if (!_formKey.currentState!.validate()) return;
    if (_conceptoSeleccionado == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleccione un concepto.'), backgroundColor: Colors.orange));
        return;
    }
    if (_estadoPagoSeleccionado == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleccione un estado de pago.'), backgroundColor: Colors.orange));
        return;
    }

    setState(() => _isLoadingGuardado = true);

    final pago = Pago(
      pacienteID: widget.paciente.pacienteID!,
      // citaID: _citaIdAsociada, // Asignar si se tiene una cita
      concepto: _conceptoSeleccionado!,
      monto: double.tryParse(_montoController.text) ?? 0.0,
      fechaPago: DateTime.now().toUtc(), // La BD también podría tener un DEFAULT CURRENT_TIMESTAMP
      estadoPago: _estadoPagoSeleccionado!,
      notasExencion: _estadoPagoSeleccionado == 'Exento' ? _notasExencionController.text : null,
    );

    try {
      await _servicioBD.registrarPagoOExencion(pago);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro de pago/exención guardado exitosamente.'), backgroundColor: Colors.green),
        );
        // Limpiar formulario o navegar atrás
        // _formKey.currentState?.reset(); // No resetea bien Dropdowns y TextFields con controller
        _actualizarMontoPorConcepto(null); // Resetea concepto y monto
        _notasExencionController.clear();
        setState(() {
             _estadoPagoSeleccionado = 'Pagado'; // Reset a default
        });
        // Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el registro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingGuardado = false);
    }
  }

  @override
  void dispose() {
    _montoController.dispose();
    _notasExencionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrar Pago/Exención para ${widget.paciente.nombreCompleto}'),
      ),
      body: _isLoadingEntrevista 
          ? const Center(child: CircularProgressIndicator(semanticsLabel: 'Cargando info de entrevista...'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    Text('Paciente: ${widget.paciente.nombreCompleto}', style: Theme.of(context).textTheme.titleMedium),
                    Text('ID: ${widget.paciente.pacienteID}'),
                    const SizedBox(height: 10),

                    if (_entrevistaDelPaciente != null)
                      Card(
                        color: _entrevistaDelPaciente!.recomiendaExencion ? Colors.green[50] : Colors.orange[50],
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Info Entrevista Socioeconómica:',
                                style: TextStyle(fontWeight: FontWeight.bold, color: _entrevistaDelPaciente!.recomiendaExencion ? Colors.green.shade800 : Colors.orange.shade800),
                              ),
                              Text('Recomienda Exención: ${_entrevistaDelPaciente!.recomiendaExencion ? "Sí" : "No"}'),
                              if (_entrevistaDelPaciente!.recomiendaExencion && _entrevistaDelPaciente!.justificacionExencion != null)
                                Text('Justificación TS: ${_entrevistaDelPaciente!.justificacionExencion}'),
                            ],
                          ),
                        ),
                      ),
                    if (_entrevistaDelPaciente == null && !_isLoadingEntrevista)
                       const Text('No se encontró información de entrevista socioeconómica.', style: TextStyle(fontStyle: FontStyle.italic)),
                    
                    const SizedBox(height: 20),

                    // Concepto
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Concepto del Servicio', border: OutlineInputBorder()),
                      value: _conceptoSeleccionado,
                      hint: const Text('Seleccione el concepto'),
                      isExpanded: true,
                      items: _costosConceptos.keys.map((String valor) {
                        return DropdownMenuItem<String>(value: valor, child: Text(valor));
                      }).toList(),
                      onChanged: _actualizarMontoPorConcepto,
                      validator: (value) => value == null ? 'Seleccione un concepto' : null,
                    ),
                    const SizedBox(height: 12),

                    // Monto
                    TextFormField(
                      controller: _montoController,
                      decoration: const InputDecoration(labelText: 'Monto \$', border: OutlineInputBorder(), prefixText: '\$ '),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Ingrese el monto';
                        if (double.tryParse(value) == null) return 'Ingrese un número válido';
                        if (double.parse(value) < 0) return 'El monto no puede ser negativo';
                        return null;
                      },
                      readOnly: _conceptoSeleccionado != null && _conceptoSeleccionado != 'Otro', // Solo editable si es 'Otro'
                    ),
                    const SizedBox(height: 12),

                    // Estado del Pago
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Estado del Pago', border: OutlineInputBorder()),
                      value: _estadoPagoSeleccionado,
                      items: _opcionesEstadoPago.map((String valor) {
                        return DropdownMenuItem<String>(value: valor, child: Text(valor));
                      }).toList(),
                      onChanged: (String? nuevoValor) {
                        setState(() {
                          _estadoPagoSeleccionado = nuevoValor;
                          // Si se selecciona "Exento" y ya cargó la entrevista, podría autocompletar notas si no lo hizo antes
                          if (nuevoValor == 'Exento' && _entrevistaDelPaciente?.recomiendaExencion == true) {
                             _notasExencionController.text = _entrevistaDelPaciente?.justificacionExencion ?? _notasExencionController.text;
                          }
                        });
                      },
                      validator: (value) => value == null ? 'Seleccione un estado' : null,
                    ),
                    const SizedBox(height: 12),

                    // Notas de Exención (visible si el estado es 'Exento')
                    if (_estadoPagoSeleccionado == 'Exento')
                      TextFormField(
                        controller: _notasExencionController,
                        decoration: const InputDecoration(labelText: 'Notas de Exención (Obligatorio si es Exento)', border: OutlineInputBorder()),
                        maxLines: 3,
                        validator: (value) {
                          if (_estadoPagoSeleccionado == 'Exento' && (value == null || value.trim().isEmpty)) {
                            return 'Ingrese las notas para la exención.';
                          }
                          return null;
                        },
                      ),
                    const SizedBox(height: 30),

                    _isLoadingGuardado
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                            icon: const Icon(Icons.receipt_long),
                            label: const Text('Registrar Movimiento'),
                            onPressed: _registrarPago,
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16.0)),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}