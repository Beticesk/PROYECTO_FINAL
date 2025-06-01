// lib/modelos_globales/modelo_pago.dart

// Si decides usar un Enum en Dart para EstadoPago, podrías definirlo aquí o globalmente.
// enum EstadoPagoEnum { Pagado, Exento, Pendiente }

class Pago {
  final int? pagoID; // Nullable si es nuevo y la BD lo autogenera
  final int pacienteID; // Requerido
  final int? citaID; // Opcional, si el pago está ligado a una cita específica
  final String concepto; // Ej. "Consulta Médica", "Certificado Discapacidad" [cite: 2]
  final double monto;   // Ej. 150.00 [cite: 2]
  DateTime? fechaPago; // Puede ser asignado por la app o tener DEFAULT en BD
  final String estadoPago; // Ej. 'Pagado', 'Exento', 'Pendiente' [cite: 4]
  final String? notasExencion; // Requerido si es 'Exento' [cite: 4]
  // final int? entrevistaSocialIDRef; // Opcional si quieres un enlace directo

  Pago({
    this.pagoID,
    required this.pacienteID,
    this.citaID,
    required this.concepto,
    required this.monto,
    this.fechaPago,
    required this.estadoPago,
    this.notasExencion,
    // this.entrevistaSocialIDRef,
  }) {
    // Asegurar que fechaPago tenga un valor si no se provee,
    // aunque la BD también podría tener un DEFAULT CURRENT_TIMESTAMP.
    fechaPago ??= DateTime.now().toUtc();
  }

  // Función auxiliar interna para parsear fechas de forma segura
  static DateTime? _parsearFecha(dynamic valorFecha) {
    if (valorFecha == null) return null;
    if (valorFecha is DateTime) return valorFecha;
    if (valorFecha is String) return DateTime.tryParse(valorFecha);
    return null;
  }

  factory Pago.desdeMapa(Map<String, dynamic> mapa) {
    return Pago(
      pagoID: mapa['pagoid'] as int?,
      pacienteID: mapa['pacienteid'] as int,
      citaID: mapa['citaid'] as int?,
      concepto: mapa['concepto'] as String,
      // El monto en la BD es numeric, el driver podría devolverlo como String o num.
      // Hacemos una conversión robusta.
      monto: (mapa['monto'] is String)
          ? (double.tryParse(mapa['monto'] as String) ?? 0.0)
          : ((mapa['monto'] as num?)?.toDouble() ?? 0.0),
      fechaPago: _parsearFecha(mapa['fechapago']),
      estadoPago: mapa['estadopago'] as String,
      notasExencion: mapa['notasexencion'] as String?,
      // entrevistaSocialIDRef: mapa['entrevistasocialid_ref'] as int?,
    );
  }

  Map<String, dynamic> aMapa() {
    return {
      // 'pagoid': pagoID, // No para INSERT si es SERIAL
      'pacienteid': pacienteID,
      'citaid': citaID,
      'concepto': concepto,
      'monto': monto,
      'fechapago': fechaPago?.toUtc().toIso8601String(), // Enviar en UTC
      'estadopago': estadoPago,
      'notasexencion': notasExencion,
      // 'entrevistasocialid_ref': entrevistaSocialIDRef,
    };
  }
}