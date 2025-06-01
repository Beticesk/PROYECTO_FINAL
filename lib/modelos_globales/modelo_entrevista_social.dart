// lib/modelos_globales/modelo_entrevista_social.dart

class EntrevistaSocial {
  final int? entrevistaID;
  int pacienteID;
  int? citaID; // Nullable
  DateTime? fechaEntrevista; // Corresponde a TIMESTAMP WITH TIME ZONE en PG
  String contenidoEntrevista;
  bool recomiendaExencion;
  String? justificacionExencion; // Nullable

  EntrevistaSocial({
    this.entrevistaID,
    required this.pacienteID,
    this.citaID,
    this.fechaEntrevista,
    required this.contenidoEntrevista,
    required this.recomiendaExencion,
    this.justificacionExencion,
  });

  // Método factory para crear una instancia de EntrevistaSocial desde un mapa
  factory EntrevistaSocial.desdeMapa(Map<String, dynamic> mapa) {
    // Función auxiliar interna para parsear fechas de forma segura
    DateTime? parsearFecha(dynamic valorFecha) {
      if (valorFecha == null) return null;
      if (valorFecha is DateTime) return valorFecha; // Si ya es DateTime, lo devuelve
      if (valorFecha is String) return DateTime.tryParse(valorFecha); // Si es String, intenta parsearlo
      return null; // Si es otro tipo o no se puede parsear
    }

    return EntrevistaSocial(
      entrevistaID: mapa['entrevistaid'] as int?,
      pacienteID: mapa['pacienteid'] as int, // Asegúrate que la clave sea 'pacienteid' en minúscula
      citaID: mapa['citaid'] as int?,
      
      // Aplicando la función auxiliar para el campo de fecha:
      fechaEntrevista: parsearFecha(mapa['fechaentrevista']), // <--- CAMBIO IMPORTANTE AQUÍ
      
      contenidoEntrevista: mapa['contenidoentrevista'] as String,
      recomiendaExencion: mapa['recomiendaexencion'] as bool,
      justificacionExencion: mapa['justificacionexencion'] as String?,
    );
  }

  // Método para convertir un objeto EntrevistaSocial a un mapa
  Map<String, dynamic> aMapa() {
    return {
      // 'entrevistaid': entrevistaID, // No se incluye para INSERT si es SERIAL
      'pacienteid': pacienteID,
      'citaid': citaID,
      'fechaentrevista': fechaEntrevista?.toUtc().toIso8601String(), // Buena práctica usar UTC para timestamps
      'contenidoentrevista': contenidoEntrevista,
      'recomiendaexencion': recomiendaExencion,
      'justificacionexencion': justificacionExencion,
    };
  }
}