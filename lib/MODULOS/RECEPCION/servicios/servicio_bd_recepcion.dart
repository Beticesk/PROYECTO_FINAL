// lib/modulos/recepcion/servicios/servicio_bd_recepcion.dart
import 'package:flutter/foundation.dart';
import 'package:pos_proyecto/modelos_globales/modelo_cita.dart';
import 'package:pos_proyecto/modelos_globales/modelo_entrevista_social.dart';
import 'package:pos_proyecto/modelos_globales/modelo_pago.dart';
// Asegúrate que las rutas de importación sean correctas
import '../../../servicios_globales/servicio_conexion_bd.dart';
import '../../../modelos_globales/modelo_paciente.dart';

class ServicioBDRecepcion {
  final ServicioConexionBD _servicioConexion = ServicioConexionBD();

  Future<int?> registrarNuevoPaciente(Paciente paciente) async {
    // Retornará el ID del nuevo paciente si es exitoso, o null si falla.
    bool conexionAbierta = await _servicioConexion.abrirConexion();
    if (!conexionAbierta || _servicioConexion.conexion == null) {
      if (kDebugMode) {
        print('RECEPCION_SERVICIO_BD ERROR: No se pudo abrir la conexión para registrar paciente.');
      }
      throw Exception('Error de conexión: No se pudo conectar a la base de datos.');
    }
    final conn = _servicioConexion.conexion!;

    try { // <--- Inicio del TRY principal para la operación de BD
      final List<List<dynamic>> resultado = await conn.query( 
        '''
        INSERT INTO pacientes (
          nombrecompleto, fechanacimiento, contactotelefono, contactoemail, 
          idioma, fecharegistrosistema, documentacionincompleta, 
          certificadodiscapacidadsol, certificadodiscapacidadentreg, 
          fechainiciotratamientogeneral, fechafintratamientogeneral
        ) VALUES (
          @nombrecompleto, @fechanacimiento, @contactotelefono, @contactoemail,
          @idioma, @fecharegistrosistema, @documentacionincompleta,
          @certificadodiscapacidadsol, @certificadodiscapacidadentreg,
          @fechainiciotratamientogeneral, @fechafintratamientogeneral
        ) RETURNING pacienteid; 
        ''',
        substitutionValues: paciente.aMapa(),
      );

      if (resultado.isNotEmpty && resultado.first.isNotEmpty) {
        final dynamic idDevuelto = resultado.first[0]; 
        int? nuevoPacienteId;

        if (idDevuelto is int) {
          nuevoPacienteId = idDevuelto;
        } else if (idDevuelto is String) {
          nuevoPacienteId = int.tryParse(idDevuelto);
        }
        
        if (nuevoPacienteId != null) {
          if (kDebugMode) {
            print('RECEPCION_SERVICIO_BD INFO: Paciente "${paciente.nombreCompleto}" registrado con ID: $nuevoPacienteId');
          }
          return nuevoPacienteId;
        } else {
          if (kDebugMode) {
            print('RECEPCION_SERVICIO_BD WARNING: No se pudo convertir el ID del paciente registrado a int. Valor devuelto: $idDevuelto');
          }
          return null;
        }
      } else {
        if (kDebugMode) {
          print('RECEPCION_SERVICIO_BD WARNING: No se pudo obtener el ID del paciente registrado (resultado vacío).');
        }
        return null;
      }
    } catch (e) { // <--- AÑADIDO EL BLOQUE CATCH
      if (kDebugMode) {
        print('RECEPCION_SERVICIO_BD ERROR: Error al ejecutar INSERT para nuevo paciente: $e');
      }
      rethrow; // Relanzar para que la UI pueda manejar el error si es necesario
    }
    // No es necesario un finally aquí si la conexión se maneja de forma más global,
    // o si solo se cierra al final de la vida de la app.
  }
  

  Future<List<Paciente>> buscarPacientesPorNombre(String terminoBusqueda) async {
    bool conexionAbierta = await _servicioConexion.abrirConexion();
    if (!conexionAbierta || _servicioConexion.conexion == null) {
      if (kDebugMode) print('RECEPCION_SERVICIO_BD ERROR: Sin conexión para buscar pacientes.');
      throw Exception('Error de conexión.');
    }
    final conn = _servicioConexion.conexion!;
    List<Paciente> pacientesEncontrados = [];

    try {
      // Usamos ILIKE para búsqueda insensible a mayúsculas/minúsculas
      // y % para buscar coincidencias parciales.
      final String consulta = '''
        SELECT * FROM pacientes 
        WHERE nombrecompleto ILIKE @terminoBusqueda
        ORDER BY nombrecompleto ASC;
      ''';

      final List<Map<String, Map<String, dynamic>>> resultados = await conn.mappedResultsQuery(
        consulta,
        substitutionValues: {
          'terminoBusqueda': '%$terminoBusqueda%', // Añade los % para el LIKE
        },
      );

      for (final fila in resultados) {
        final mapaPaciente = fila['pacientes']; 
        if (mapaPaciente != null) {
          pacientesEncontrados.add(Paciente.desdeMapa(mapaPaciente));
        } else {
           if (kDebugMode) print('RECEPCION_SERVICIO_BD WARNING: Estructura de fila inesperada para búsqueda de pacientes: ${fila.keys}');
        }
      }
      if (kDebugMode) print('RECEPCION_SERVICIO_BD INFO: ${pacientesEncontrados.length} pacientes encontrados para "$terminoBusqueda".');
      return pacientesEncontrados;
    } catch (e) {
      if (kDebugMode) print('RECEPCION_SERVICIO_BD ERROR: Error al buscar pacientes: $e');
      rethrow;
    }
  }


  Future<Paciente?> obtenerPacientePorId(int pacienteId) async {
    // (Implementación similar a la de ServicioBDTrabajoSocial,
    // pero puedes decidir si es mejor tenerlo aquí duplicado o en un servicio global)
    // Por ahora, puedes copiar la implementación de obtenerPacientePorId de ServicioBDTrabajoSocial
    // y adaptarla si es necesario.
    bool conexionAbierta = await _servicioConexion.abrirConexion();
    if (!conexionAbierta || _servicioConexion.conexion == null) {
      if (kDebugMode) print('RECEPCION_SERVICIO_BD ERROR: Sin conexión para obtener paciente por ID.');
      throw Exception('Error de conexión.');
    }
    final conn = _servicioConexion.conexion!;
    try {
      final resultados = await conn.mappedResultsQuery(
        'SELECT * FROM pacientes WHERE pacienteid = @id',
        substitutionValues: {'id': pacienteId},
      );
      if (resultados.isNotEmpty) {
        final mapaPaciente = resultados.first['pacientes'];
        if (mapaPaciente != null) {
          return Paciente.desdeMapa(mapaPaciente);
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('RECEPCION_SERVICIO_BD ERROR: Error al obtener paciente $pacienteId: $e');
      rethrow;
    }
  }

  //este es mi nuevo metodo para poder hacer que solo leea y no edite la entrevista ppipipipipi
   Future<EntrevistaSocial?> obtenerEntrevistaDelPaciente(int pacienteId) async {
    // Este método es muy similar al obtenerEntrevistaMasReciente de Trabajo Social
    bool conexionAbierta = await _servicioConexion.abrirConexion();
    if (!conexionAbierta || _servicioConexion.conexion == null) {
      if (kDebugMode) print('RECEPCION_SERVICIO_BD ERROR: Sin conexión para obtener entrevista del paciente.');
      throw Exception('Error de conexión.');
    }
    final conn = _servicioConexion.conexion!;

    try {
      final List<Map<String, Map<String, dynamic>>> resultados = await conn.mappedResultsQuery(
        'SELECT * FROM entrevistassociales WHERE pacienteid = @id ORDER BY fechaentrevista DESC LIMIT 1',
        substitutionValues: {'id': pacienteId},
      );

      if (resultados.isNotEmpty) {
        final mapaEntrevista = resultados.first['entrevistassociales'];
        if (mapaEntrevista != null) {
          return EntrevistaSocial.desdeMapa(mapaEntrevista);
        } else {
          if (kDebugMode) print('RECEPCION_SERVICIO_BD WARNING: No se encontró la clave de tabla "entrevistassociales" en el resultado: ${resultados.first.keys}');
          return null;
        }
      }
      return null; // No se encontró entrevista para este paciente
    } catch (e) {
      if (kDebugMode) print('RECEPCION_SERVICIO_BD ERROR: Error al obtener entrevista para paciente $pacienteId: $e');
      rethrow;
    }
  }

//nuevo metodo para el regitro de citas cuchau
Future<void> agendarNuevaCita(Cita nuevaCita) async {
    bool conexionAbierta = await _servicioConexion.abrirConexion();
    if (!conexionAbierta || _servicioConexion.conexion == null) {
      if (kDebugMode) {
        print('RECEPCION_SERVICIO_BD ERROR: No se pudo abrir la conexión para agendar cita.');
      }
      throw Exception('Error de conexión: No se pudo conectar a la base de datos.');
    }
    final conn = _servicioConexion.conexion!;

    try {
      // El CitaID es SERIAL y se autogenerará.
      // El estado inicial de la cita será 'Programada'.
      // profesionalasignado será null por ahora.
      // faltajustificada y frecuenciasiguientecitarecomendada no se establecen al crear la cita.
      
      // Usamos el método aMapa() de tu modelo Cita.
      // Asegúrate que aMapa() NO incluya 'citaid' si es SERIAL.
      // Y que los nombres de las claves del mapa coincidan con los placeholders.
      Map<String, dynamic> valoresParaBD = nuevaCita.aMapa();
      
      // Aseguramos que el estado sea 'Programada' si no viene ya así desde el objeto Cita
      // y que profesionalasignado sea null si no se ha implementado.
      // El modelo Cita debería manejar esto en su constructor o el que llama debe asegurar estos valores.
      // Por ahora, asumimos que el objeto nuevaCita ya viene con el estado correcto ('Programada')
      // y profesionalasignado como null.

      await conn.query(
        '''
        INSERT INTO citas (
          pacienteid, 
          fechahoracita, 
          tipoconsulta, 
          profesionalasignado, 
          estadocita
          -- faltajustificada y frecuenciasiguientecitarecomendada tienen defaults o son nullables
        ) VALUES (
          @pacienteid, 
          @fechahoracita, 
          @tipoconsulta, 
          @profesionalasignado, 
          @estadocita
        );
        ''', // Nombres de columna en minúsculas como en tu BD
        substitutionValues: {
          'pacienteid': nuevaCita.pacienteID,
          'fechahoracita': nuevaCita.fechaHoraCita.toUtc(), // Siempre guarda en UTC
          'tipoconsulta': nuevaCita.tipoConsulta,
          'profesionalasignado': nuevaCita.profesionalAsignado, // Será null por ahora
          'estadocita': nuevaCita.estadoCita ?? 'Programada', // Default a 'Programada' si es null
        },
      );

      if (kDebugMode) {
        print('RECEPCION_SERVICIO_BD INFO: Nueva cita agendada para PacienteID ${nuevaCita.pacienteID} el ${nuevaCita.fechaHoraCita}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('RECEPCION_SERVICIO_BD ERROR: Error al agendar nueva cita: $e');
      }
      rethrow;
    }
  }


/////otro metodo para no poder editar la reserva de cita si ya se creo uwu



  

  Future<List<Cita>> obtenerCitasPendientesDelPaciente(int pacienteId) async {
    bool conexionAbierta = await _servicioConexion.abrirConexion();
    if (!conexionAbierta || _servicioConexion.conexion == null) {
      if (kDebugMode) print('RECEPCION_SERVICIO_BD ERROR: Sin conexión para obtener citas pendientes.');
      throw Exception('Error de conexión.');
    }
    final conn = _servicioConexion.conexion!;
    List<Cita> citasList = [];

    try {
      // Selecciona citas que están 'Programada' o 'Confirmada' y cuya fecha/hora es hoy o en el futuro.
      // Ordenadas por fecha y hora de la cita.
      final String consulta = '''
        SELECT * FROM citas 
        WHERE pacienteid = @pacienteId 
          AND (estadocita = 'Programada' OR estadocita = 'Confirmada')
          AND fechahoracita >= CURRENT_TIMESTAMP 
        ORDER BY fechahoracita ASC;
      ''';
      // Nota: CURRENT_TIMESTAMP incluye la hora actual. Si quieres citas de todo el día de hoy en adelante,
      // podrías usar fechahoracita >= DATE_TRUNC('day', CURRENT_TIMESTAMP)

      final List<Map<String, Map<String, dynamic>>> resultados = await conn.mappedResultsQuery(
        consulta,
        substitutionValues: {'pacienteId': pacienteId},
      );

      for (final fila in resultados) {
        final mapaCita = fila['citas'];
        if (mapaCita != null) {
          citasList.add(Cita.desdeMapa(mapaCita));
        } else {
          if (kDebugMode) print('RECEPCION_SERVICIO_BD WARNING: Estructura de fila inesperada para citas: ${fila.keys}');
        }
      }
      if (kDebugMode) print('RECEPCION_SERVICIO_BD INFO: ${citasList.length} citas pendientes encontradas para paciente ID $pacienteId.');
      return citasList;
    } catch (e) {
      if (kDebugMode) print('RECEPCION_SERVICIO_BD ERROR: Error al obtener citas pendientes para paciente $pacienteId: $e');
      rethrow;
    }
  }

//otro metodooo pero este es para filtrar por fechas las citas, osea organizar las citas en el boton ver citas simo que si

Future<List<Map<String, dynamic>>> obtenerCitasConNombrePacientePorFecha(DateTime fecha) async {
    bool conexionAbierta = await _servicioConexion.abrirConexion();
    if (!conexionAbierta || _servicioConexion.conexion == null) {
      if (kDebugMode) print('RECEPCION_SERVICIO_BD ERROR: Sin conexión para obtener citas por fecha.');
      throw Exception('Error de conexión.');
    }
    final conn = _servicioConexion.conexion!;
    
    // Formatear la fecha para que coincida con el inicio y fin del día en la BD
    // PostgreSQL puede comparar un DATE con un TIMESTAMP, pero para ser explícitos:
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
        WHERE c.fechahoracita >= @fechaInicio AND c.fechahoracita <= @fechaFin
        ORDER BY c.fechahoracita ASC;
      ''';

      // mappedResultsQuery devuelve List<Map<String, Map<String, dynamic>>>
      // donde la primera clave es el nombre de la tabla.
      // Para JOINs, puede ser un poco más complejo o devolver un mapa plano si las columnas no colisionan.
      // Vamos a usar conn.query y mapear manualmente para mayor control con JOINs.
      
      final List<List<dynamic>> resultadosCrudos = await conn.query(
        consulta,
        substitutionValues: {
          'fechaInicio': fechaInicio,
          'fechaFin': fechaFin,
        },
      );

      List<Map<String, dynamic>> citasConNombre = [];
      if (resultadosCrudos.isNotEmpty) {
        // Necesitamos saber el orden de las columnas seleccionadas para mapear correctamente
        // Asumiendo el orden: citaid, fechahoracita, tipoconsulta, profesionalasignado, estadocita, pacienteid, nombre_paciente
        for (final fila in resultadosCrudos) {
          citasConNombre.add({
            'citaid': fila[0],
            'fechahoracita': fila[1] as DateTime, // El driver debe convertirlo a DateTime
            'tipoconsulta': fila[2],
            'profesionalasignado': fila[3],
            'estadocita': fila[4],
            'pacienteid': fila[5],
            'nombre_paciente': fila[6],
          });
        }
      }
      
      if (kDebugMode) print('RECEPCION_SERVICIO_BD INFO: ${citasConNombre.length} citas encontradas para la fecha ${fecha.toLocal().toString().split(' ')[0]}.');
      return citasConNombre;
    } catch (e) {
      if (kDebugMode) print('RECEPCION_SERVICIO_BD ERROR: Error al obtener citas por fecha: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> obtenerTodasCitasPendientesConNombrePaciente() async {
    bool conexionAbierta = await _servicioConexion.abrirConexion();
    if (!conexionAbierta || _servicioConexion.conexion == null) {
      if (kDebugMode) print('RECEPCION_SERVICIO_BD ERROR: Sin conexión para obtener todas las citas pendientes.');
      throw Exception('Error de conexión.');
    }
    final conn = _servicioConexion.conexion!;
    
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
        WHERE (c.estadocita = 'Programada' OR c.estadocita = 'Confirmada')
          AND c.fechahoracita >= CURRENT_TIMESTAMP 
        ORDER BY c.fechahoracita ASC;
      ''';
      // Se obtienen todas las citas futuras (o desde la hora actual del día de hoy)
      // que estén programadas o confirmadas.

      final List<List<dynamic>> resultadosCrudos = await conn.query(consulta);

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
      
      if (kDebugMode) print('RECEPCION_SERVICIO_BD INFO: ${citasList.length} citas pendientes en total encontradas.');
      return citasList;
    } catch (e) {
      if (kDebugMode) print('RECEPCION_SERVICIO_BD ERROR: Error al obtener todas las citas pendientes: $e');
      rethrow;
    }
  }


// Método registrarPagoOExencion chingos de metodos piipipip
Future<void> registrarPagoOExencion(Pago nuevoPago) async {
    bool conexionAbierta = await _servicioConexion.abrirConexion();
    if (!conexionAbierta || _servicioConexion.conexion == null) {
      if (kDebugMode) {
        print('RECEPCION_SERVICIO_BD ERROR: No se pudo abrir la conexión para registrar el pago.');
      }
      throw Exception('Error de conexión: No se pudo conectar a la base de datos.');
    }
    final conn = _servicioConexion.conexion!;

    try {
      // El PagoID es SERIAL y se autogenerará.
      // FechaPago puede tener un DEFAULT CURRENT_TIMESTAMP en la BD o la asignamos aquí.
      // Asegúrate que tu modelo Pago y su método aMapa() estén listos.
      
      Map<String, dynamic> valoresParaBD = nuevoPago.aMapa();
      
      // Si FechaPago no se establece en el objeto y quieres que sea ahora:
      if (valoresParaBD['fechapago'] == null) {
        valoresParaBD['fechapago'] = DateTime.now().toUtc().toIso8601String();
      }

      // Asegurarse de que las claves en substitutionValues coincidan con los placeholders
      // y los placeholders con las columnas de la BD (en minúsculas).
      await conn.query(
        '''
        INSERT INTO pagos (
          pacienteid, citaid, concepto, monto, 
          fechapago, estadopago, notasexencion
          -- , entrevistasocialid_ref -- Descomenta si añadiste esta columna
        ) VALUES (
          @pacienteid, @citaid, @concepto, @monto,
          @fechapago, @estadopago, @notasexencion
          -- , @entrevistasocialid_ref -- Descomenta si añadiste esta columna
        );
        ''', 
        substitutionValues: valoresParaBD,
      );

      if (kDebugMode) {
        print('RECEPCION_SERVICIO_BD INFO: Pago/Exención registrado para PacienteID ${nuevoPago.pacienteID} con concepto "${nuevoPago.concepto}"');
      }
    } catch (e) {
      if (kDebugMode) {
        print('RECEPCION_SERVICIO_BD ERROR: Error al registrar pago/exención: $e');
      }
      rethrow;
    }
  }


  Future<List<Map<String, dynamic>>> obtenerPacientesConRecomendacionExencion() async {
    bool conexionAbierta = await _servicioConexion.abrirConexion();
    if (!conexionAbierta || _servicioConexion.conexion == null) {
      if (kDebugMode) print('RECEPCION_SERVICIO_BD ERROR: Sin conexión para obtener pacientes con recomendación de exención.');
      throw Exception('Error de conexión.');
    }
    final conn = _servicioConexion.conexion!;
    List<Map<String, dynamic>> pacientesConRecomendacion = [];

    try {
      // Selecciona pacientes que tienen una entrevista social donde se recomienda exención.
      // Se une con pacientes para obtener el nombre.
      // Podríamos añadir una condición para no mostrar si ya se registró un pago 'Exento' para un servicio principal reciente,
      // pero para empezar, mostremos todos con recomendación. Recepción puede verificar al procesar.
      final String consulta = '''
        SELECT 
          p.pacienteid,
          p.nombrecompleto,
          es.fechaentrevista,
          es.justificacionexencion
        FROM pacientes p
        JOIN entrevistassociales es ON p.pacienteid = es.pacienteid
        WHERE es.recomiendaexencion = TRUE
        ORDER BY es.fechaentrevista DESC; 
      ''';
      // Opcional: podrías filtrar para que no aparezcan si ya tienen un pago "Exento" muy reciente
      // añadiendo un LEFT JOIN a la tabla pagos y una condición en el WHERE.

      final List<List<dynamic>> resultadosCrudos = await conn.query(consulta);

      if (resultadosCrudos.isNotEmpty) {
        for (final fila in resultadosCrudos) {
          pacientesConRecomendacion.add({
            'pacienteid': fila[0],
            'nombrecompleto': fila[1],
            'fechaentrevista': fila[2] as DateTime?, // El driver debería convertirlo
            'justificacionexencion': fila[3],
          });
        }
      }
      if (kDebugMode) print('RECEPCION_SERVICIO_BD INFO: ${pacientesConRecomendacion.length} pacientes con recomendación de exención encontrados.');
      return pacientesConRecomendacion;
    } catch (e) {
      if (kDebugMode) print('RECEPCION_SERVICIO_BD ERROR: Error al obtener pacientes con recomendación de exención: $e');
      rethrow;
    }
  }

}