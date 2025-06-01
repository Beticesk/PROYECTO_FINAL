// lib/modulos/medico/pantallas/pantalla_agenda_medico.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../servicios/servicio_bd_medico.dart';
import './pantalla_gestion_consulta.dart'; // Para navegar a gestionar la consulta

// Enum para definir la vista actual de la agenda
enum VistaAgendaMedico { proximas, historial }

class PantallaAgendaMedico extends StatefulWidget {
  final String nombreMedico;
  const PantallaAgendaMedico({super.key, this.nombreMedico = "Dr. Ejemplo"});

  @override
  State<PantallaAgendaMedico> createState() => _PantallaAgendaMedicoState();

  


}




class _PantallaAgendaMedicoState extends State<PantallaAgendaMedico> {
  final ServicioBDMedico _servicioBD = ServicioBDMedico();
  DateTime? _fechaFiltrada; 
  List<Map<String, dynamic>>? _citasMostradas;
  bool _isLoading = true;
  String? _error;

  // NUEVA VARIABLE DE ESTADO para controlar la vista
  VistaAgendaMedico _vistaActual = VistaAgendaMedico.proximas;

  @override
  void initState() {
    super.initState();
    _cargarDatosVista(); // Llama al método que carga según _vistaActual y _fechaFiltrada
  }

  // Método unificado y modificado para cargar citas según la vista y el filtro
  Future<void> _cargarDatosVista({DateTime? fechaFiltroAplicado, bool cambiarAProximas = false}) async {
    // Si se está cambiando a la vista de próximas citas desde el historial, o refrescando sin filtro de fecha
    if (cambiarAProximas || (_vistaActual == VistaAgendaMedico.proximas && fechaFiltroAplicado == null)) {
      _fechaFiltrada = null; // Asegurar que no haya filtro de fecha
      _vistaActual = VistaAgendaMedico.proximas; // Asegurar que la vista sea de próximas
    } else if (fechaFiltroAplicado != null) {
      _fechaFiltrada = fechaFiltroAplicado; // Aplicar filtro de fecha
      _vistaActual = VistaAgendaMedico.proximas; // Filtrar por fecha solo aplica a próximas citas
    }
    // Si _vistaActual es historial, fechaFiltroAplicado se ignora para la carga principal de historial

    setState(() {
      _isLoading = true;
      _error = null;
      _citasMostradas = null;
    });

    try {
      List<Map<String, dynamic>> citas;
      if (_vistaActual == VistaAgendaMedico.historial) {
        citas = await _servicioBD.obtenerConsultasRealizadasDelMedico(
          nombreProfesional: widget.nombreMedico,
        );
      } else { // Vista de Próximas Citas (con o sin filtro de fecha)
        if (_fechaFiltrada == null) {
          citas = await _servicioBD.obtenerTodasProximasCitasDelMedico(
            nombreProfesional: widget.nombreMedico,
          );
        } else {
          citas = await _servicioBD.obtenerCitasDelMedicoPorFecha(
            fecha: _fechaFiltrada!,
            nombreProfesional: widget.nombreMedico,
          );
        }
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

  Future<void> _seleccionarFechaParaFiltrar(BuildContext context) async {
    final DateTime? fechaElegida = await showDatePicker(
      context: context,
      initialDate: _fechaFiltrada ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)), // Ver hasta un año atrás
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es', 'ES'),
    );
    if (fechaElegida != null) {
      // Al seleccionar una fecha, siempre mostramos las "próximas" (o activas) de ese día
      _cargarDatosVista(fechaFiltroAplicado: fechaElegida);
    }
  }

  void _cambiarAVista(VistaAgendaMedico nuevaVista) {
    if (_vistaActual != nuevaVista || (nuevaVista == VistaAgendaMedico.proximas && _fechaFiltrada != null)) {
      setState(() {
        _vistaActual = nuevaVista;
        // Si cambiamos a una vista (próximas o historial) desde el toggle, reseteamos el filtro de fecha
        _fechaFiltrada = null; 
      });
      _cargarDatosVista(); 
    }
  }

  String _formatearSoloHora(DateTime fechaHora) {
    return DateFormat('HH:mm', 'es_ES').format(fechaHora.toLocal());
  }
  
  void _irAGestionarConsulta(Map<String, dynamic> citaMap) {
    final int pacienteId = citaMap['pacienteid'];
    final int citaId = citaMap['citaid'];
    final DateTime fechaHoraCita = citaMap['fechahoracita'];
    final String tipoConsulta = citaMap['tipoconsulta'] ?? 'N/A';

    // Solo se puede gestionar consulta si la cita no está 'Realizada' o 'Cancelada'
    // (o la lógica que prefieras para el historial)
    // Para citas del historial ('Realizada'), podríamos navegar a una vista de detalle de esa consulta específica.
    // Por ahora, la navegación es la misma, PantallaGestionConsulta puede mostrar info si ya está realizada.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PantallaGestionConsulta(
          pacienteId: pacienteId,
          citaId: citaId,
          fechaHoraCitaOriginal: fechaHoraCita,
          tipoConsultaOriginal: tipoConsulta,
        ),
      ),
    ).then((seActualizoCita) {
      if (seActualizoCita == true && mounted) {
        _cargarDatosVista(fechaFiltroAplicado: _fechaFiltrada); 
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatoFechaDisplayTitulo = DateFormat('EEEE dd MMMM yyyy', 'es_ES');
    String tituloEncabezado;

    if (_vistaActual == VistaAgendaMedico.historial) {
      tituloEncabezado = 'Historial de Consultas Realizadas';
    } else {
      tituloEncabezado = _fechaFiltrada == null 
          ? 'Próximas Citas Agendadas' 
          : formatoFechaDisplayTitulo.format(_fechaFiltrada!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Agenda - ${widget.nombreMedico}'),
        actions: [
          // Solo mostrar el filtro de fecha si estamos en la vista de próximas citas
          if (_vistaActual == VistaAgendaMedico.proximas)
            IconButton(
              icon: const Icon(Icons.calendar_today),
              tooltip: 'Filtrar Próximas por Fecha',
              onPressed: () => _seleccionarFechaParaFiltrar(context),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar Vista Actual',
            onPressed: () => _cargarDatosVista(fechaFiltroAplicado: _fechaFiltrada),
          ),

          IconButton(
          icon: const Icon(Icons.logout), // Icono de cerrar sesión
          tooltip: 'Cerrar Sesión',        // Texto que aparece al dejar presionado
          onPressed: () {
            // Lógica para cerrar sesión:
            // 1. (Opcional) Limpiar cualquier dato de sesión guardado (tokens, etc.)
            //    Ejemplo: si usaras SharedPreferences para un token:
            //    final prefs = await SharedPreferences.getInstance();
            //    await prefs.remove('user_token');

            // 2. Navegar de vuelta a la pantalla de Login y eliminar todas las rutas anteriores
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/', // Navega a la ruta raíz, que en tu app es LoginPage
                   // porque tienes home: const LoginPage() en MaterialApp
              (Route<dynamic> route) => false, // Esta condición elimina todas las rutas anteriores del stack
            );
          },
        ),


        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, // Para que el ToggleButtons ocupe el ancho
        children: [
          // Selector de Vista (Próximas / Historial)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ToggleButtons(
              isSelected: [
                _vistaActual == VistaAgendaMedico.proximas,
                _vistaActual == VistaAgendaMedico.historial,
              ],
              onPressed: (index) {
                _cambiarAVista(index == 0 ? VistaAgendaMedico.proximas : VistaAgendaMedico.historial);
              },
              borderRadius: BorderRadius.circular(8.0),
              constraints: BoxConstraints(minWidth: (MediaQuery.of(context).size.width - 48) / 2, minHeight: 40.0), // Ajusta el -48 según tu padding
              children: const [
                Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Próximas Citas')),
                Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Historial')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 8.0),
            child: Text(
              tituloEncabezado,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildListaCitasMedico()),
        ],
      ),
    );
  }

  Widget _buildListaCitasMedico() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_error!, style: const TextStyle(color: Colors.red))));
    }
    if (_citasMostradas == null || _citasMostradas!.isEmpty) {
      String mensajeVacio = 'No hay información para mostrar.';
      if (_vistaActual == VistaAgendaMedico.historial) {
        mensajeVacio = 'No hay consultas realizadas en el historial.';
      } else {
        mensajeVacio = _fechaFiltrada == null 
            ? 'No tiene próximas citas programadas.' 
            : 'No tiene citas programadas para esta fecha.';
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(mensajeVacio, style: const TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
        )
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8.0),
      itemCount: _citasMostradas!.length,
      itemBuilder: (context, index) {
        final citaMap = _citasMostradas![index];
        final DateTime fechaHoraCita = citaMap['fechahoracita'];
        final String nombrePaciente = citaMap['nombre_paciente'] ?? 'N/A';
        final String tipoConsulta = citaMap['tipoconsulta'] ?? 'N/A';
        final String estadoCita = citaMap['estadocita'] ?? 'N/A';
        final String? observacionMedico = citaMap['frecuenciasiguientecitarecomendada']; // Para el historial

        String subtitulo;
        if (_vistaActual == VistaAgendaMedico.historial) {
          subtitulo = '${DateFormat('EEE dd/MM/yy', 'es_ES').format(fechaHoraCita.toLocal())} - $tipoConsulta\nObservación: ${observacionMedico ?? "N/A"}';
        } else {
          subtitulo = '${DateFormat('EEE dd/MM/yy', 'es_ES').format(fechaHoraCita.toLocal())} - $tipoConsulta\nEstado: $estadoCita';
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
          elevation: 2.0,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _vistaActual == VistaAgendaMedico.historial ? Colors.grey[300] : Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: _vistaActual == VistaAgendaMedico.historial ? Colors.black54 : Theme.of(context).colorScheme.onPrimaryContainer,
              child: Text(_formatearSoloHora(fechaHoraCita)),
            ),
            title: Text(nombrePaciente, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(subtitulo),
            isThreeLine: true,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
               _irAGestionarConsulta(citaMap); // Esta función ya la tienes
            },
          ),
        );
      },
    );
  }
}