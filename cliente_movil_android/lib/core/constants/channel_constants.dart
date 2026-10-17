// ============================================================================
// SismoGuard — Constantes de Canales Nativos (Method/Event Channels)
// ============================================================================
// Define los nombres de todos los canales de comunicación entre Dart y el
// código nativo (Kotlin/Swift) para el Foreground Service y sensores.
// ============================================================================

/// Constantes para los canales de comunicación Dart ↔ Nativo.
abstract class ChannelConstants {
  ChannelConstants._();

  // ═══════════════════════════════════════════════════════════
  //  METHOD CHANNELS (Dart → Nativo: llamadas RPC)
  // ═══════════════════════════════════════════════════════════

  /// Canal principal para controlar el Foreground Service.
  /// Métodos: startService, stopService, isRunning
  static const String foregroundServiceMethod =
      'com.sismoguard.app/foreground_service';

  /// Canal para configurar el acelerómetro nativo.
  /// Métodos: setSampleRate, calibrate, getDeviceSensorInfo
  static const String accelerometerMethod =
      'com.sismoguard.app/accelerometer';

  /// Canal para controlar el comportamiento del dispositivo (alarmas).
  /// Métodos: setVolume, setVibrationPattern, wakeScreen, activateSiren
  static const String deviceControlMethod =
      'com.sismoguard.app/device_control';

  /// Canal para gestión de SMS silencioso.
  /// Métodos: sendSilentSms, checkSmsPermission
  static const String smsFallbackMethod =
      'com.sismoguard.app/sms_fallback';

  // ═══════════════════════════════════════════════════════════
  //  EVENT CHANNELS (Nativo → Dart: streams continuos)
  // ═══════════════════════════════════════════════════════════

  /// Stream continuo de datos del acelerómetro a 50Hz.
  /// Emite: Map<String, double> con keys: x, y, z, timestamp
  static const String accelerometerStream =
      'com.sismoguard.app/accelerometer_stream';

  /// Stream de eventos del Foreground Service.
  /// Emite: Map<String, dynamic> con status, errors, metrics
  static const String serviceStatusStream =
      'com.sismoguard.app/service_status_stream';

  /// Stream de mensajes Cell Broadcast interceptados.
  /// Emite: Map<String, String> con messageId, body, channelId
  static const String cellBroadcastStream =
      'com.sismoguard.app/cell_broadcast_stream';

  // ═══════════════════════════════════════════════════════════
  //  NOMBRES DE MÉTODOS (para evitar strings mágicos)
  // ═══════════════════════════════════════════════════════════

  // Métodos del Foreground Service
  static const String methodStartService = 'startService';
  static const String methodStopService = 'stopService';
  static const String methodIsRunning = 'isRunning';
  static const String methodUpdateNotification = 'updateNotification';

  // Métodos del Acelerómetro
  static const String methodSetSampleRate = 'setSampleRate';
  static const String methodCalibrate = 'calibrate';
  static const String methodGetSensorInfo = 'getDeviceSensorInfo';

  // Métodos de Control de Dispositivo
  static const String methodSetVolume = 'setVolume';
  static const String methodSetVibration = 'setVibrationPattern';
  static const String methodWakeScreen = 'wakeScreen';
  static const String methodActivateSiren = 'activateSiren';
  static const String methodDeactivateSiren = 'deactivateSiren';
}
