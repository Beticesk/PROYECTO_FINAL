// lib/modulos/medico/servicios/servicio_bd_medico.dart
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pos_proyecto/modelos_globales/modelo_entrevista_social.dart';
// Asegúrate que las rutas de importación sean correctas
import '../../../servicios_globales/servicio_conexion_bd.dart';

import '../../../modelos_globales/modelo_paciente.dart'; // Para el nombre del Paciente

class ServicioBDMedico {
  final ServicioConexionBD _servicioConexion = ServicioConexionBD();


  Future<List<Map<String, dynamic>>> obtenerCitasDelMedicoPorFecha({
    required DateTime fecha,
    required String nombreProfesional, // O un ID si lo prefieres
  }) async {
    bool conexionAbierta = await _servicioConexion.abrirConexion();
    if (!conexionAbierta || _servicioConexion.conexion == null) {
      if (kDebugMode) print('MEDICO_SERVICIO_BD ERROR: Sin conexión para obtener citas del médico.');
      throw Exception('Error de conexión.');
    }
    final conn = _servicioConexion.conexion!;

    final fechaInicio = DateTime(fecha.year, fecha.month, fecha.day, 0, 0, 0).toUtc();
    final fechaFin = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59).toUtc();

    try {
      final String consulta = '''
        SELECT 
          c.citaid, 
          c.fechahoracita, 
          c.tipoconsulta, 
          c.profesionalasignado, 
          c.estadocita,
          p.pacienteid,
          p.nombrecompleto AS nombre_paciente 
        FROM citas c
        JOIN pacientes p ON c.pacienteid = p.pacienteid
        WHERE c.profesionalasignado = @nombreProfesional
          AND c.fechahoracita >= @fechaInicio 
          AND c.fechahoracita <= @fechaFin
          AND (c.estadocita = 'Programada' OR c.estadocita = 'Confirmada') -- Solo citas activas
        ORDER BY c.fechahoracita ASC;
      ''';
      
      final List<List<dynamic>> resultadosCrudos = await conn.query(
        consulta,
        substitutionValues: {
          'nombreProfesional': nombreProfesional,
          'fechaInicio': fechaInicio,
          'fechaFin': fechaFin,
        },
      );

      List<Map<String, dynamic>> citasList = [];
      if (resultadosCrudos.isNotEmpty) {
        for (final fila in resultadosCrudos) {
          citasList.add({
            'citaid': fila[0],
            'fechahoracita': fila[1] as DateTime,
            'tipoconsulta': fila[2],
            'profesionalasignado': fila[3],
            'estadocita': fila[4],
            'pacienteid': fila[5],
            'nombre_paciente': fila[6],
          });
        }
      }
      
      if (kDebugMode) print('MEDICO_SERVICIO_BD INFO: ${citasList.length} citas encontradas para $nombreProfesional en ${DateFormat('dd/MM/yyyy', 'es_ES').format(fecha)}.');
      return citasList;
    } catch (e) {
      if (kDebugMode) print('MEDICO_SERVICIO_BD ERROR: Error al obtener citas del médico: $e');
      rethrow;
    }
  }

  // Nuevo método para obtener detalles del paciente Y su última entrevista social
  Future<Map<String, dynamic>?> obtenerDetallesCompletosPacienteParaMedico(int pacienteId) async {
    bool conexionAbierta = await _servicioConexion.abrirConexion();
    if (!conexionAbierta || _servicioConexion.conexion == null) {
      if (kDebugMode) print('MEDICO_SERVICIO_BD ERROR: Sin conexión para obtener detalles completos del paciente.');
      throw Exception('Error de conexión.');
    }
    final conn = _servicioConexion.conexion!;

    Paciente? paciente;
    EntrevistaSocial? entrevista;

    try {
      // Obtener datos del paciente
      final List<Map<String, Map<String, dynamic>>> resultadosPaciente = await conn.mappedResultsQuery(
        'SELECT * FROM pacientes WHERE pacienteid = @id',
        substitutionValues: {'id': pacienteId},
      );
      if (resultadosPaciente.isNotEmpty) {
        final mapaPaciente = resultadosPaciente.first['pacientes'];
        if (mapaPaciente != null) {
          paciente = Paciente.desdeMapa(mapaPaciente);
        }
      }

      // Obtener última entrevista social del paciente (si existe)
      final List<Map<String, Map<String, dynamic>>> resultadosEntrevista = await conn.mappedResultsQuery(
        'SELECT * FROM entrevistassociales WHERE pacienteid = @id ORDER BY fechaentrevista DESC LIMIT 1',
        substitutionValues: {'id': pacienteId},
      );
      if (resultadosEntrevista.isNotEmpty) {
        final mapaEntrevista = resultadosEntrevista.first['entrevistassociales'];
        if (mapaEntrevista != null) {
          entrevista = EntrevistaSocial.desdeMapa(mapaEntrevista);
        }
      }

      if (paciente != null) {
        return {'paciente': paciente, 'entrevista': entrevista}; // Devuelve un mapa con ambos objetos
      }
      return null; // Si no se encontró el paciente
    } catch (e) {
      if (kDebugMode) print('MEDICO_SERVICIO_BD ERROR: Error al obtener detalles completos del paciente $pacienteId: $e');
      rethrow;
    }
  }

  // Nuevo método para finalizar una consulta
  Future<void> finalizarConsulta({
    required int citaId,
    required String nuevoEstadoCita, // ej. 'Realizada'
    String? frecuenciaProximaCita,
    int? pacienteId, // Necesario si se actualizan datos del paciente
    bool? certificadoEntregado, // Opcional para actualizar en la tabla pacientes
    // DateTime? fechaFinTratamiento, // Opcional
  }) async {
    bool conexionAbierta = await _servicioConexion.abrirConexion();
    if (!conexionAbierta || _servicioConexion.conexion == null) {
      if (kDebugMode) print('MEDICO_SERVICIO_BD ERROR: Sin conexión para finalizar consulta.');
      throw Exception('Error de conexión.');
    }
    final conn = _servicioConexion.conexion!;

    try {
      // Iniciar una transacción si vas a hacer múltiples actualizaciones
      await conn.transaction((ctx) async {
        // 1. Actualizar la tabla 'citas'
        await ctx.query(
          '''
          UPDATE citas 
          SET estadocita = @nuevoEstado, 
              frecuenciasiguientecitarecomendada = @frecuencia 
          WHERE citaid = @citaId;
          ''',
          substitutionValues: {
            'nuevoEstado': nuevoEstadoCita,
            'frecuencia': frecuenciaProximaCita,
            'citaId': citaId,
          },
        );

        // 2. Opcional: Actualizar la tabla 'pacientes'
        if (pacienteId != null && certificadoEntregado != null) {
          await ctx.query(
            '''
            UPDATE pacientes
            SET certificadodiscapacidadentreg = @certificadoEntregado
            WHERE pacienteid = @pacienteId;
            ''',
            substitutionValues: {
              'certificadoEntregado': certificadoEntregado,
              'pacienteId': pacienteId,
            },
          );
        }
        // Aquí podrías añadir más actualizaciones a la tabla pacientes si es necesario
        // ej. para fechaFinTratamientoGeneral
      });

      if (kDebugMode) print('MEDICO_SERVICIO_BD INFO: Consulta CitaID $citaId finalizada. Estado: $nuevoEstadoCita.');
    } catch (e) {
      if (kDebugMode) print('MEDICO_SERVICIO_BD ERROR: Error al finalizar consulta CitaID $citaId: $e');
      rethrow;
    }
  }
  


// NUEVO MÉTODO o puedes modificar el existente si solo tendrás esta lógica
Future<List<Map<String, dynamic>>> obtenerTodasProximasCitasDelMedico({
    required String nombreProfesional, // Sigue recibiendo el nombre del profesional
  }) async {
    bool conexionAbierta = await _servicioConexion.abrirConexion();
    if (!conexionAbierta || _servicioConexion.conexion == null) {
      if (kDebugMode) print('MEDICO_SERVICIO_BD ERROR: Sin conexión para obtener todas las próximas citas.');
      throw Exception('Error de conexión.');
    }
    final conn = _servicioConexion.conexion!;

    try {
      String consultaSQL;
      Map<String, dynamic> substitutionMap = {'nombreProfesional': nombreProfesional};

      // Lógica para ajustar la consulta si es "Dr. Ejemplo" y queremos incluir las no asignadas
      if (nombreProfesional == "Dr. Ejemplo") {
        consultaSQL = '''
          SELECT 
            c.citaid, 
            c.fechahoracita, 
            c.tipoconsulta, 
            c.profesionalasignado, 
            c.estadocita,
            p.pacienteid,
            p.nombrecompleto AS nombre_paciente 
          FROM citas c
          JOIN pacientes p ON c.pacienteid = p.pacienteid
          WHERE 
            (c.profesionalasignado = @nombreProfesional OR c.profesionalasignado IS NULL) -- <--- MODIFICACIÓN AQUÍ
            AND c.fechahoracita >= CURRENT_TIMESTAMP 
            AND (c.estadocita = 'Programada' OR c.estadocita = 'Confirmada') 
          ORDER BY c.fechahoracita ASC;
        ''';
      } else {
        // Para cualquier otro médico, solo mostramos las asignadas directamente a él
        consultaSQL = '''
          SELECT 
            c.citaid, 
            c.fechahoracita, 
            c.tipoconsulta, 
            c.profesionalasignado, 
            c.estadocita,
            p.pacienteid,
            p.nombrecompleto AS nombre_paciente 
          FROM citas c
          JOIN pacientes p ON c.pacienteid = p.pacienteid
          WHERE 
            c.profesionalasignado = @nombreProfesional -- Solo las asignadas a este profesional
            AND c.fechahoracita >= CURRENT_TIMESTAMP 
            AND (c.estadocita = 'Programada' OR c.estadocita = 'Confirmada') 
          ORDER BY c.fechahoracita ASC;
        ''';
      }
      
      final List<List<dynamic>> resultadosCrudos = await conn.query(
        consultaSQL,
        substitutionValues: substitutionMap,
      );

      List<Map<String, dynamic>> citasList = [];
      if (resultadosCrudos.isNotEmpty) {
        for (final fila in resultadosCrudos) {
          citasList.add({
            'citaid': fila[0],
            'fechahoracita': fila[1] as DateTime,
            'tipoconsulta': fila[2],
            'profesionalasignado': fila[3], // Puede ser null
            'estadocita': fila[4],
            'pacienteid': fila[5],
            'nombre_paciente': fila[6],
          });
        }
      }
      
      if (kDebugMode) print('MEDICO_SERVICIO_BD INFO: ${citasList.length} próximas citas encontradas para $nombreProfesional (incluyendo no asignadas si es Dr. Ejemplo).');
      return citasList;
    } catch (e) {
      if (kDebugMode) print('MEDICO_SERVICIO_BD ERROR: Error al obtener todas las próximas citas del médico: $e');
      rethrow;
    }
  }


Future<List<Map<String, dynamic>>> obtenerHistorialCitasPacienteParaMedico(int pacienteId) async {
    bool conexionAbierta = await _servicioConexion.abrirConexion();
    if (!conexionAbierta || _servicioConexion.conexion == null) {
      if (kDebugMode) print('MEDICO_SERVICIO_BD ERROR: Sin conexión para obtener historial de citas.');
      throw Exception('Error de conexión.');
    }
    final conn = _servicioConexion.conexion!;
    
    try {
      final String consulta = '''
        SELECT 
          citaid, 
          fechahoracita, 
          tipoconsulta, 
          profesionalasignado, 
          estadocita,
          frecuenciasiguientecitarecomendada 
        FROM citas
        WHERE pacienteid = @pacienteId
        ORDER BY fechahoracita DESC; -- Más recientes primero
      ''';
      
      // Usamos conn.query porque el resultado no está anidado por nombre de tabla directamente
      // y podemos mapear las columnas directamente por su índice o nombre.
      final List<List<dynamic>> resultadosCrudos = await conn.query(
        consulta,
        substitutionValues: {'pacienteId': pacienteId},
      );

      List<Map<String, dynamic>> historialCitas = [];
      if (resultadosCrudos.isNotEmpty) {
        // Asumiendo el orden de las columnas en el SELECT:
        // 0: citaid, 1: fechahoracita, 2: tipoconsulta, 3: profesionalasignado, 
        // 4: estadocita, 5: frecuenciasiguientecitarecomendada
        for (final fila in resultadosCrudos) {
          historialCitas.add({
            'citaid': fila[0] as int?, // El ID de la cita
            'fechahoracita': fila[1] as DateTime, // El driver postgres convierte timestamp a DateTime
            'tipoconsulta': fila[2] as String?,
            'profesionalasignado': fila[3] as String?,
            'estadocita': fila[4] as String?,
            'frecuenciasiguientecitarecomendada': fila[5] as String?, // Esta es la "nota" del médico
          });
        }
      }
      if (kDebugMode) print('MEDICO_SERVICIO_BD INFO: ${historialCitas.length} citas encontradas en el historial para PacienteID $pacienteId.');
      return historialCitas;
    } catch (e) {
      if (kDebugMode) print('MEDICO_SERVICIO_BD ERROR: Error al obtener historial de citas para paciente $pacienteId: $e');
      rethrow;
    }
  }

Future<List<Map<String, dynamic>>> obtenerConsultasRealizadasDelMedico({
    required String nombreProfesional,
    int limite = 50, 
  }) async {
    bool conexionAbierta = await _servicioConexion.abrirConexion();
    if (!conexionAbierta || _servicioConexion.conexion == null) {
      if (kDebugMode) print('MEDICO_SERVICIO_BD ERROR: Sin conexión para obtener consultas realizadas.');
      throw Exception('Error de conexión.');
    }
    final conn = _servicioConexion.conexion!;

    try {
      String consultaSQL;
      Map<String, dynamic> substitutionMap = {
        'nombreProfesional': nombreProfesional,
        'limite': limite,
        'estadoRealizada': 'Realizada' // Para usar en la consulta
      };

      // Lógica para ajustar la consulta si es "Dr. Ejemplo" y queremos incluir las no asignadas
      if (nombreProfesional == "Dr. Ejemplo") {
        consultaSQL = '''
          SELECT 
            c.citaid, 
            c.fechahoracita, 
            c.tipoconsulta, 
            c.profesionalasignado, 
            c.estadocita,
            c.frecuenciasiguientecitarecomendada, 
            p.pacienteid,
            p.nombrecompleto AS nombre_paciente 
          FROM citas c
          JOIN pacientes p ON c.pacienteid = p.pacienteid
          WHERE 
            (c.profesionalasignado = @nombreProfesional OR c.profesionalasignado IS NULL) -- <--- MODIFICACIÓN AQUÍ
            AND c.estadocita = @estadoRealizada 
          ORDER BY c.fechahoracita DESC
          LIMIT @limite; 
        ''';
      } else {
        // Para cualquier otro médico, solo mostramos las asignadas directamente a él
        consultaSQL = '''
          SELECT 
            c.citaid, 
            c.fechahoracita, 
            c.tipoconsulta, 
            c.profesionalasignado, 
            c.estadocita,
            c.frecuenciasiguientecitarecomendada,
            p.pacienteid,
            p.nombrecompleto AS nombre_paciente 
          FROM citas c
          JOIN pacientes p ON c.pacienteid = p.pacienteid
          WHERE 
            c.profesionalasignado = @nombreProfesional 
            AND c.estadocita = @estadoRealizada 
          ORDER BY c.fechahoracita DESC
          LIMIT @limite;
        ''';
      }
      
      final List<List<dynamic>> resultadosCrudos = await conn.query(
        consultaSQL,
        substitutionValues: substitutionMap,
      );

      List<Map<String, dynamic>> consultasList = [];
      if (resultadosCrudos.isNotEmpty) {
        for (final fila in resultadosCrudos) {
          consultasList.add({
            'citaid': fila[0],
            'fechahoracita': fila[1] as DateTime,
            'tipoconsulta': fila[2],
            'profesionalasignado': fila[3],
            'estadocita': fila[4],
            'frecuenciasiguientecitarecomendada': fila[5],
            'pacienteid': fila[6],
            'nombre_paciente': fila[7],
          });
        }
      }
      if (kDebugMode) print('MEDICO_SERVICIO_BD INFO: ${consultasList.length} consultas realizadas encontradas para $nombreProfesional.');
      return consultasList;
    } catch (e) {
      if (kDebugMode) print('MEDICO_SERVICIO_BD ERROR: Error al obtener consultas realizadas del médico: $e');
      rethrow;
    }
  }

}