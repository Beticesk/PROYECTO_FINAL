// lib/modelos_globales/modelo_paciente.dart

class Paciente {
  final int? pacienteID; // Nullable si es nuevo y aún no tiene ID de la BD
  String nombreCompleto;
  DateTime? fechaNacimiento; // Corresponde a DATE en PG
  String? contactoTelefono;
  String? contactoEmail;
  String? idioma;
  DateTime? fechaRegistroSistema; // Corresponde a TIMESTAMP WITH TIME ZONE en PG
  bool documentacionIncompleta;
  bool certificadoDiscapacidadSol;
  bool certificadoDiscapacidadEntreg;
  DateTime? fechaInicioTratamientoGeneral; // Corresponde a DATE en PG
  DateTime? fechaFinTratamientoGeneral; // Corresponde a DATE en PG

  Paciente({
    this.pacienteID,
    required this.nombreCompleto,
    this.fechaNacimiento,
    this.contactoTelefono,
    this.contactoEmail,
    this.idioma,
    this.fechaRegistroSistema,
    this.documentacionIncompleta = false, // Valor por defecto
    this.certificadoDiscapacidadSol = false, // Valor por defecto
    this.certificadoDiscapacidadEntreg = false, // Valor por defecto
    this.fechaInicioTratamientoGeneral,
    this.fechaFinTratamientoGeneral,
  });

  // Método factory para crear una instancia de Paciente desde un mapa (ej. desde la BD)
  // Los nombres de las claves del mapa deben coincidir con los nombres de las columnas de tu tabla Pacientes (en minúsculas).
  factory Paciente.desdeMapa(Map<String, dynamic> mapa) {
    // Función auxiliar interna para parsear fechas de forma segura
    DateTime? parsearFecha(dynamic valorFecha) {
      if (valorFecha == null) return null;
      if (valorFecha is DateTime) return valorFecha; // Si ya es DateTime, lo devuelve
      if (valorFecha is String) return DateTime.tryParse(valorFecha); // Si es String, intenta parsearlo
      // Podrías añadir un log aquí si el tipo no es esperado y quieres depurar
      // print('Valor de fecha inesperado: $valorFecha, tipo: ${valorFecha.runtimeType}');
      return null; // Si es otro tipo o no se puede parsear
    }

    return Paciente(
      pacienteID: mapa['pacienteid'] as int?,
      nombreCompleto: mapa['nombrecompleto'] as String,
      fechaNacimiento: parsearFecha(mapa['fechanacimiento']),
      contactoTelefono: mapa['contactotelefono'] as String?,
      contactoEmail: mapa['contactoemail'] as String?,
      idioma: mapa['idioma'] as String?,
      fechaRegistroSistema: parsearFecha(mapa['fecharegistrosistema']),
      documentacionIncompleta: mapa['documentacionincompleta'] as bool? ?? false,
      certificadoDiscapacidadSol: mapa['certificadodiscapacidadsol'] as bool? ?? false,
      certificadoDiscapacidadEntreg: mapa['certificadodiscapacidadentreg'] as bool? ?? false,
      fechaInicioTratamientoGeneral: parsearFecha(mapa['fechainiciotratamientogeneral']),
      fechaFinTratamientoGeneral: parsearFecha(mapa['fechafintratamientogeneral']),
    );
  }

  // Método para convertir un objeto Paciente a un mapa (ej. para enviar a la BD)
  // Los nombres de las claves deben coincidir con los nombres de las columnas (en minúsculas).
  Map<String, dynamic> aMapa() {
    return {
      // 'pacienteid': pacienteID, // No se incluye pacienteID para INSERT si es SERIAL y autogenerado
      // Se incluiría para UPDATE. Si tu lógica de INSERT lo necesita nulo, puedes incluirlo.
      'nombrecompleto': nombreCompleto,
      // Para campos DATE en PostgreSQL, enviar solo la parte de la fecha es más seguro.
      'fechanacimiento': fechaNacimiento?.toIso8601String().split('T').first,
      'contactotelefono': contactoTelefono,
      'contactoemail': contactoEmail,
      'idioma': idioma,
      // Para campos TIMESTAMP en PostgreSQL, el formato ISO completo está bien.
      'fecharegistrosistema': fechaRegistroSistema?.toUtc().toIso8601String(), // Es buena práctica usar UTC para timestamps
      'documentacionincompleta': documentacionIncompleta,
      'certificadodiscapacidadsol': certificadoDiscapacidadSol,
      'certificadodiscapacidadentreg': certificadoDiscapacidadEntreg,
      'fechainiciotratamientogeneral': fechaInicioTratamientoGeneral?.toIso8601String().split('T').first,
      'fechafintratamientogeneral': fechaFinTratamientoGeneral?.toIso8601String().split('T').first,
    };
  }
}