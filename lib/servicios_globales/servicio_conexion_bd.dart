// lib/servicios_globales/servicio_conexion_bd.dart
import 'package:postgres/postgres.dart';
import 'package:flutter/foundation.dart'; // Para kDebugMode

class ServicioConexionBD {
  // Patrón Singleton
  static final ServicioConexionBD _instancia = ServicioConexionBD._interno();
  factory ServicioConexionBD() {
    return _instancia;
  }
  ServicioConexionBD._interno();

  PostgreSQLConnection? _conexion;

  // Getter para que otros servicios puedan acceder a la instancia de conexión
  // Podrías llamarlo 'conexionActiva' o similar si prefieres.
  PostgreSQLConnection? get conexion {
    return _conexion;
  }

  Future<bool> abrirConexion() async { // Devuelve bool para indicar éxito/fallo
    if (_conexion == null || _conexion!.isClosed) {
      _conexion = PostgreSQLConnection(
        'localhost',             // Host de tu servidor PostgreSQL
        5432,                    // Puerto (por defecto 5432)
        'pos_proyecto',          // Nombre de tu NUEVA base de datos
        username: 'postgres',       // Tu usuario de PostgreSQL
        password: '159753',       // Tu contraseña de PostgreSQL
        // OJO: Considera no tener contraseñas directamente en el código en producción
      );
      try {
        await _conexion!.open();
        if (kDebugMode) {
          print('CONEXION BD: Conectado a PostgreSQL (pos_proyecto)');
        }
        return true;
      } catch (e) {
        if (kDebugMode) {
          print('CONEXION BD ERROR: Error al conectar a PostgreSQL (pos_proyecto): $e');
        }
        _conexion = null; // Asegúrate de resetear en caso de error
        // Podrías querer rethrow e o manejarlo de otra forma según tu estrategia de errores
        return false;
      }
    }
    // Si ya estaba abierta y no cerrada, también es un éxito en cierto modo
    return _conexion != null && !_conexion!.isClosed;
  }

  Future<void> cerrarConexion() async {
    if (_conexion != null && !_conexion!.isClosed) {
      await _conexion!.close();
      if (kDebugMode) {
        print('CONEXION BD: Conexión a PostgreSQL (pos_proyecto) cerrada');
      }
      _conexion = null; // Limpia la instancia después de cerrar
    }
  }

  // Este servicio ya NO contendrá métodos como obtenerItinerarios, agregarItinerario, etc.
  // Su única responsabilidad es manejar el estado de la conexión.
}