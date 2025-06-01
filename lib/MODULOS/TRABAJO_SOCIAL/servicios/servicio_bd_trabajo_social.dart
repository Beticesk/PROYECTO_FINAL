// lib/modulos/TRABAJO_SOCIAL/servicios/servicio_bd_trabajo_social.dart

import 'package:flutter/foundation.dart';
// Asegúrate que las rutas de importación sean correctas
import '../../../servicios_globales/servicio_conexion_bd.dart';
import '../../../modelos_globales/modelo_entrevista_social.dart';
import '../../../modelos_globales/modelo_paciente.dart';

class ServicioBDTrabajoSocial {
  final ServicioConexionBD _servicioConexion = ServicioConexionBD();

  Future<void> guardarEntrevistaSocial(EntrevistaSocial entrevista) async {
    bool conexionAbierta = await _servicioConexion.abrirConexion();
    if (!conexionAbierta || _servicioConexion.conexion == null) {
      if (kDebugMode) {
        print('TS_SERVICIO_BD ERROR: No se pudo abrir la conexión para guardar entrevista.');
      }
      throw Exception('Error de conexión: No se pudo conectar a la base de datos.');
    }
    final conn = _servicioConexion.conexion!;

    try {
      final fechaParaBD = entrevista.fechaEntrevista ?? DateTime.now().toUtc();
      await conn.query(
        '''
        INSERT INTO EntrevistasSociales (
          PacienteID, CitaID, FechaEntrevista, ContenidoEntrevista, 
          RecomiendaExencion, JustificacionExencion
        ) VALUES (
          @pacienteID, @citaID, @fechaEntrevista, @contenidoEntrevista, 
          @recomiendaExencion, @justificacionExencion
        )
        ''',
        substitutionValues: {
          'pacienteID': entrevista.pacienteID,
          'citaID': entrevista.citaID,
          'fechaEntrevista': fechaParaBD,
          'contenidoEntrevista': entrevista.contenidoEntrevista,
          'recomiendaExencion': entrevista.recomiendaExencion,
          'justificacionExencion': entrevista.justificacionExencion,
        },
      );
      if (kDebugMode) {
        print('TS_SERVICIO_BD INFO: Entrevista social guardada para PacienteID ${entrevista.pacienteID}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('TS_SERVICIO_BD ERROR: Error al guardar entrevista social: $e');
      }
      rethrow;
    }
  }

  Future<Paciente?> obtenerPacientePorId(int pacienteId) async {
    bool conexionAbierta = await _servicioConexion.abrirConexion();
    if (!conexionAbierta || _servicioConexion.conexion == null) {
      if (kDebugMode) {
        print('TS_SERVICIO_BD ERROR: Sin conexión para obtener paciente.');
      }
      throw Exception('Error de conexión.');
    }
    final conn = _servicioConexion.conexion!;

    try {
      final List<Map<String, Map<String, dynamic>>> resultados = await conn.mappedResultsQuery(
        'SELECT * FROM "pacientes" WHERE "pacienteid" = @id', // Usa comillas dobles si tus nombres de tabla/columna tienen mayúsculas
        substitutionValues: {'id': pacienteId},
      );

      if (resultados.isNotEmpty) {
        // El paquete postgres suele devolver nombres de tablas y columnas en minúsculas
        // como claves en el mapa, a menos que se especifique lo contrario o se usen comillas en la creación.
        // Intenta primero con minúsculas, que es lo más común.
        final mapaPaciente = resultados.first['pacientes'] ?? resultados.first['Pacientes'];
        if (mapaPaciente != null) {
          return Paciente.desdeMapa(mapaPaciente);
        } else {
           if (kDebugMode) print('TS_SERVICIO_BD WARNING: No se encontró la clave de tabla esperada en el resultado de mappedResultsQuery para Pacientes: ${resultados.first.keys}');
           return null;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('TS_SERVICIO_BD ERROR: Error al obtener paciente $pacienteId: $e');
      }
      rethrow;
    }
  }

  // Puedes añadir más métodos aquí, como obtenerEntrevistasPorPaciente(int pacienteId)
   Future<EntrevistaSocial?> obtenerEntrevistaMasReciente(int pacienteId) async {
    bool conexionAbierta = await _servicioConexion.abrirConexion();
    if (!conexionAbierta || _servicioConexion.conexion == null) {
      if (kDebugMode) print('TS_SERVICIO_BD ERROR: Sin conexión para obtener entrevista más reciente.');
      throw Exception('Error de conexión.');
    }
    final conn = _servicioConexion.conexion!;

    try {
      // Esta consulta asume que quieres la más reciente si pudieran existir varias.
      // Si solo esperas una, puedes quitar el ORDER BY y LIMIT 1 si el pacienteID es único en la práctica para entrevistas.
      final List<Map<String, Map<String, dynamic>>> resultados = await conn.mappedResultsQuery(
        'SELECT * FROM entrevistassociales WHERE pacienteid = @id ORDER BY fechaentrevista DESC LIMIT 1',
        substitutionValues: {'id': pacienteId},
      );

      if (resultados.isNotEmpty) {
        final mapaEntrevista = resultados.first['entrevistassociales'];
        if (mapaEntrevista != null) {
          return EntrevistaSocial.desdeMapa(mapaEntrevista);
        } else {
          if (kDebugMode) print('TS_SERVICIO_BD WARNING: No se encontró la clave de tabla "entrevistassociales" en el resultado: ${resultados.first.keys}');
          return null;
        }
      }
      return null; // No se encontró entrevista para este paciente
    } catch (e) {
      if (kDebugMode) print('TS_SERVICIO_BD ERROR: Error al obtener entrevista más reciente para paciente $pacienteId: $e');
      rethrow;
    }
  }


 // MÉTODO MODIFICADO: Ahora obtiene todos los pacientes sin entrevista, sin filtro de fecha
  Future<List<Paciente>> obtenerPacientesSinEntrevista() async { // <--- Nombre cambiado (opcional, pero recomendado)
    bool conexionAbierta = await _servicioConexion.abrirConexion();
    if (!conexionAbierta || _servicioConexion.conexion == null) {
      if (kDebugMode) print('TS_SERVICIO_BD ERROR: Sin conexión para obtener pacientes sin entrevista.');
      throw Exception('Error de conexión.');
    }
    final conn = _servicioConexion.conexion!;
    List<Paciente> pacientesSinEntrevista = [];

    try {
      // Selecciona pacientes (p) que NO TIENEN una entrada correspondiente en entrevistassociales (es)
      final String consulta = '''
        SELECT p.*
        FROM pacientes p
        LEFT JOIN entrevistassociales es ON p.pacienteid = es.pacienteid
        WHERE es.entrevistaid IS NULL
        ORDER BY p.fecharegistrosistema DESC; -- Opcional: ordenar por fecha de registro, más nuevos primero
      ''';
      // Ya no está la condición: AND DATE(p.fecharegistrosistema AT TIME ZONE 'UTC') = CURRENT_DATE;

      final List<Map<String, Map<String, dynamic>>> resultados = await conn.mappedResultsQuery(consulta);

      for (final fila in resultados) {
        final mapaPaciente = fila['pacientes']; 
        if (mapaPaciente != null) {
          pacientesSinEntrevista.add(Paciente.desdeMapa(mapaPaciente));
        } else {
            if (kDebugMode) print('TS_SERVICIO_BD WARNING: Estructura de fila inesperada para pacientes sin entrevista: ${fila.keys}');
        }
      }
      if (kDebugMode) print('TS_SERVICIO_BD INFO: ${pacientesSinEntrevista.length} pacientes sin entrevista encontrados.');
      return pacientesSinEntrevista;
    } catch (e) {
      if (kDebugMode) print('TS_SERVICIO_BD ERROR: Error al obtener pacientes sin entrevista: $e');
      rethrow;
    }
  }
}