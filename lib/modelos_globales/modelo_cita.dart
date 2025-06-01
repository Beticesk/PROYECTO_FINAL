// lib/modelos_globales/modelo_cita.dart

// Si quieres usar un enum para EstadoCita, defínelo aquí o en un archivo de enums global.
// enum EstadoCitaEnum { Programada, Confirmada, Realizada, Cancelada, NoAsistio }

class Cita {
  final int? citaID; // Nullable si es nueva y la BD lo autogenera
  int pacienteID;
  DateTime fechaHoraCita; // No nullable, se debe proveer
  String? tipoConsulta;
  String? profesionalAsignado; // Será null por ahora, según tu especificación
  String? estadoCita; // Idealmente un Enum, por ahora String. Default 'Programada'
  bool? faltaJustificada; // Nullable
  String? frecuenciaSiguienteCitaRecomendada; // Nullable

  Cita({
    this.citaID,
    required this.pacienteID,
    required this.fechaHoraCita,
    this.tipoConsulta,
    this.profesionalAsignado, // Se puede omitir al crear la cita desde Recepción por ahora
    this.estadoCita = 'Programada', // Valor por defecto al crear una nueva cita
    this.faltaJustificada,
    this.frecuenciaSiguienteCitaRecomendada,
  });

  // Función auxiliar interna para parsear fechas de forma segura desde la BD
  static DateTime? _parsearFecha(dynamic valorFecha) {
    if (valorFecha == null) return null;
    if (valorFecha is DateTime) return valorFecha; // Si ya es DateTime, lo devuelve
    if (valorFecha is String) return DateTime.tryParse(valorFecha); // Si es String, intenta parsearlo
    return null; // Si es otro tipo o no se puede parsear
  }

  // Factory constructor para crear una instancia de Cita desde un mapa (ej. desde la BD)
  factory Cita.desdeMapa(Map<String, dynamic> mapa) {
    return Cita(
      citaID: mapa['citaid'] as int?,
      pacienteID: mapa['pacienteid'] as int,
      // fechaHoraCita debe existir en el mapa, y si es null, se usa un valor por defecto o se maneja el error
      fechaHoraCita: _parsearFecha(mapa['fechahoracita']) ?? DateTime(1900), // Fallback si es null y no debería serlo. Ajusta según tu lógica.
      tipoConsulta: mapa['tipoconsulta'] as String?,
      profesionalAsignado: mapa['profesionalasignado'] as String?,
      estadoCita: mapa['estadocita'] as String?,
      faltaJustificada: mapa['faltajustificada'] as bool?,
      frecuenciaSiguienteCitaRecomendada: mapa['frecuenciasiguientecitarecomendada'] as String?,
    );
  }

  // Método para convertir un objeto Cita a un mapa (ej. para enviar a la BD)
  Map<String, dynamic> aMapa() {
    return {
      // 'citaid': citaID, // No se incluye para INSERT si es SERIAL y autogenerado por la BD
      'pacienteid': pacienteID,
      'fechahoracita': fechaHoraCita.toUtc().toIso8601String(), // Enviar en UTC a la BD
      'tipoconsulta': tipoConsulta,
      'profesionalasignado': profesionalAsignado, // Será null si no se asigna
      'estadocita': estadoCita,
      // Los campos nullables como faltaJustificada y frecuenciaSiguienteCitaRecomendada
      // se enviarán como null si no tienen valor, lo cual está bien para la BD.
      'faltajustificada': faltaJustificada,
      'frecuenciasiguientecitarecomendada': frecuenciaSiguienteCitaRecomendada,
    };
  }
}