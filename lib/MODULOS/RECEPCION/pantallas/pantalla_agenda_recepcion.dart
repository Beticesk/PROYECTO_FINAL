// lib/modulos/recepcion/pantallas/pantalla_agenda_recepcion.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../servicios/servicio_bd_recepcion.dart';
import './pantalla_ver_paciente_recepcion.dart';

class PantallaAgendaRecepcion extends StatefulWidget {
  const PantallaAgendaRecepcion({super.key});

  @override
  State<PantallaAgendaRecepcion> createState() => _PantallaAgendaRecepcionState();
}

class _PantallaAgendaRecepcionState extends State<PantallaAgendaRecepcion> {
  final ServicioBDRecepcion _servicioBD = ServicioBDRecepcion();
  DateTime? _fechaFiltrada; // Null si se muestran todas las próximas, una fecha si se filtra por día
  List<Map<String, dynamic>>? _citasMostradas;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarCitas(); // Carga todas las citas pendientes por defecto
  }

  Future<void> _seleccionarFechaParaFiltrar(BuildContext context) async {
    final DateTime? fechaElegida = await showDatePicker(
      context: context,
      initialDate: _fechaFiltrada ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'ES'),
    );
    if (fechaElegida != null) {
      setState(() {
        _fechaFiltrada = fechaElegida;
      });
      _cargarCitas(fecha: fechaElegida);
    }
  }

  Future<void> _cargarCitas({DateTime? fecha}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _citasMostradas = null; 
      if (fecha != null) { // Si se provee una fecha, actualizamos _fechaFiltrada
          _fechaFiltrada = fecha;
      }
    });
    try {
      List<Map<String, dynamic>> citas;
      if (fecha == null) { // Si no hay fecha específica, cargar todas las pendientes
        citas = await _servicioBD.obtenerTodasCitasPendientesConNombrePaciente();
      } else { // Cargar citas para la fecha específica
        citas = await _servicioBD.obtenerCitasConNombrePacientePorFecha(fecha);
      }
      
      if (mounted) {
        setState(() {
          _citasMostradas = citas;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error al cargar citas: $e';
        });
      }
    }
  }

  void _mostrarTodasLasProximasCitas() {
    setState(() {
      _fechaFiltrada = null; // Limpiar el filtro de fecha
    });
    _cargarCitas(); // Carga todas las pendientes
  }


  String _formatearFechaHora(DateTime fechaHora) {
    return DateFormat('dd/MM/yyyy HH:mm', 'es_ES').format(fechaHora.toLocal());
  }
   String _formatearSoloHora(DateTime fechaHora) {
    return DateFormat('HH:mm', 'es_ES').format(fechaHora.toLocal());
  }


  void _verDetallesPaciente(int pacienteId) {
     Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PantallaVerPacienteRecepcion(pacienteId: pacienteId),
      ),
    ).then((_){
      // Al regresar, podríamos querer recargar la lista de citas si algo cambió
      _cargarCitas(fecha: _fechaFiltrada);
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatoFechaDisplay = DateFormat('EEEE dd MMMM yyyy', 'es_ES');
    String tituloVista = _fechaFiltrada == null 
        ? 'Todas las Próximas Citas' 
        : formatoFechaDisplay.format(_fechaFiltrada!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda / Citas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Filtrar por Fecha',
            onPressed: () => _seleccionarFechaParaFiltrar(context),
          ),
          if (_fechaFiltrada != null) // Mostrar solo si hay un filtro de fecha activo
            IconButton(
              icon: const Icon(Icons.list_alt_outlined),
              tooltip: 'Mostrar Todas las Próximas',
              onPressed: _mostrarTodasLasProximasCitas,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar Vista Actual',
            onPressed: () => _cargarCitas(fecha: _fechaFiltrada),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tituloVista,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildListaCitas()),
        ],
      ),
    );
  }

  Widget _buildListaCitas() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_error!, style: const TextStyle(color: Colors.red))));
    }
    if (_citasMostradas == null || _citasMostradas!.isEmpty) {
      return Center(child: Text(
        _fechaFiltrada == null 
          ? 'No hay próximas citas programadas.' 
          : 'No hay citas programadas para esta fecha.',
        style: const TextStyle(fontSize: 16))
      );
    }

return ListView.builder(
      itemCount: _citasMostradas!.length,
      itemBuilder: (context, index) {
        final citaMap = _citasMostradas![index];
        final DateTime fechaHoraCita = citaMap['fechahoracita'];
        final String nombrePaciente = citaMap['nombre_paciente'] ?? 'N/A';
        final String tipoConsulta = citaMap['tipoconsulta'] ?? 'N/A';
        final String estadoCita = citaMap['estadocita'] ?? 'N/A';
        final int pacienteId = citaMap['pacienteid'];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ListTile(
            leading: Tooltip( // <--- Widget Tooltip
              message: _formatearFechaHora(fechaHoraCita), // Mensaje del tooltip
              child: CircleAvatar( // <--- El CircleAvatar es el HIJO del Tooltip
                child: Text(_formatearSoloHora(fechaHoraCita)),
                // SIN parámetro 'tooltip' aquí dentro de CircleAvatar
              ),
            ),
            title: Text(nombrePaciente, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text('Tipo: $tipoConsulta - Estado: $estadoCita\nFecha: ${DateFormat('dd/MM/yyyy', 'es_ES').format(fechaHoraCita.toLocal())}'),
            isThreeLine: true,
            onTap: () {
              _verDetallesPaciente(pacienteId);
            },
          ),
        );
      },
    );
  }
}