// ============================================================================
// SismoGuard — Excepciones Personalizadas
// ============================================================================

/// Excepción del servidor remoto.
class ServerException implements Exception {
  const ServerException({this.message = 'Error del servidor', this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'ServerException: $message (código: $statusCode)';
}

/// Excepción de caché / almacenamiento local.
class CacheException implements Exception {
  const CacheException({this.message = 'Error de almacenamiento local'});
  final String message;

  @override
  String toString() => 'CacheException: $message';
}

/// Excepción del Foreground Service nativo.
class ForegroundServiceException implements Exception {
  const ForegroundServiceException({
    this.message = 'Error en el servicio de detección',
  });
  final String message;

  @override
  String toString() => 'ForegroundServiceException: $message';
}

/// Excepción al parsear mensajes CAP XML.
class CapParsingException implements Exception {
  const CapParsingException({
    this.message = 'Error al procesar alerta CAP',
    this.xmlFragment,
  });
  final String message;
  final String? xmlFragment;

  @override
  String toString() => 'CapParsingException: $message';
}

/// Excepción de comunicaciones (BLE Mesh, LoRa, SMS).
class CommunicationException implements Exception {
  const CommunicationException({
    this.message = 'Error de comunicación',
    this.channel,
  });
  final String message;
  final String? channel; // 'bridgefy', 'meshtastic', 'sms', 'ntn'

  @override
  String toString() => 'CommunicationException [$channel]: $message';
}

/// Excepción del sensor acelerómetro.
class SensorException implements Exception {
  const SensorException({
    this.message = 'Error del sensor',
  });
  final String message;

  @override
  String toString() => 'SensorException: $message';
}

/// Excepción de permisos insuficientes.
class PermissionException implements Exception {
  const PermissionException({
    this.message = 'Permiso no concedido',
    this.permission,
  });
  final String message;
  final String? permission;

  @override
  String toString() => 'PermissionException [$permission]: $message';
}
