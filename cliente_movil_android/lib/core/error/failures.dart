// ============================================================================
// SismoGuard — Failures (Errores de Dominio)
// ============================================================================
// Patrón funcional: los Failures envuelven errores para que el dominio
// no dependa de excepciones. Se usan con Either<Failure, Success>.
// ============================================================================

import 'package:equatable/equatable.dart';

/// Clase base abstracta para todos los errores de dominio.
abstract class Failure extends Equatable {
  const Failure({this.message = 'Error inesperado', this.properties = const []});

  final String message;
  final List<Object?> properties;

  @override
  List<Object?> get props => [message, ...properties];
}

/// Error de comunicación con el servidor.
class ServerFailure extends Failure {
  const ServerFailure({super.message = 'Error de conexión con el servidor'});
}

/// Error de almacenamiento local (Hive, SQLite, SharedPrefs).
class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Error de almacenamiento local'});
}

/// Error en el servicio de detección sísmica.
class SeismicServiceFailure extends Failure {
  const SeismicServiceFailure({
    super.message = 'Error en el servicio de detección sísmica',
  });
}

/// Error al procesar una alerta CAP.
class AlertProcessingFailure extends Failure {
  const AlertProcessingFailure({
    super.message = 'Error al procesar la alerta',
  });
}

/// Error en las comunicaciones de red de malla.
class MeshCommunicationFailure extends Failure {
  const MeshCommunicationFailure({
    super.message = 'Error en la red de comunicación',
    this.channel,
  });
  final String? channel;
}

/// Error de permisos del sistema.
class PermissionFailure extends Failure {
  const PermissionFailure({
    super.message = 'Permisos insuficientes',
    this.permission,
  });
  final String? permission;
}

/// Error en la carga o inferencia del modelo CNN.
class ModelInferenceFailure extends Failure {
  const ModelInferenceFailure({
    super.message = 'Error en el modelo de clasificación',
  });
}

/// Error en la carga de mapas offline.
class MapLoadFailure extends Failure {
  const MapLoadFailure({
    super.message = 'Error al cargar el mapa offline',
  });
}
