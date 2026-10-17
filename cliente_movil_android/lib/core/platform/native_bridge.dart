// ============================================================================
// SismoGuard — Puente Nativo (Native Bridge)
// ============================================================================
// Abstracción unificada para todas las comunicaciones Dart ↔ Nativo.
// Centraliza la gestión de Method Channels y Event Channels.
// ============================================================================

import 'package:flutter/services.dart';

import '../constants/channel_constants.dart';

/// Puente de comunicación centralizado entre Dart y código nativo.
///
/// Proporciona una interfaz limpia para invocar funcionalidad nativa
/// sin exponer los detalles de los Method/Event Channels a las capas
/// superiores de la arquitectura.
class NativeBridge {
  // ─── Method Channels ───
  final MethodChannel _foregroundServiceChannel = const MethodChannel(
    ChannelConstants.foregroundServiceMethod,
  );

  final MethodChannel _accelerometerChannel = const MethodChannel(
    ChannelConstants.accelerometerMethod,
  );

  final MethodChannel _deviceControlChannel = const MethodChannel(
    ChannelConstants.deviceControlMethod,
  );

  final MethodChannel _smsFallbackChannel = const MethodChannel(
    ChannelConstants.smsFallbackMethod,
  );

  // ─── Event Channels ───
  final EventChannel _accelerometerStreamChannel = const EventChannel(
    ChannelConstants.accelerometerStream,
  );

  final EventChannel _cellBroadcastStreamChannel = const EventChannel(
    ChannelConstants.cellBroadcastStream,
  );

  // ═══════════════════════════════════════════════════════════
  //  ACELERÓMETRO
  // ═══════════════════════════════════════════════════════════

  /// Configura la tasa de muestreo del acelerómetro nativo.
  ///
  /// [rateHz] debe estar entre 25 y 100. Recomendado: 50Hz.
  Future<bool> setAccelerometerSampleRate(int rateHz) async {
    try {
      final result = await _accelerometerChannel.invokeMethod<bool>(
        ChannelConstants.methodSetSampleRate,
        {'rateHz': rateHz},
      );
      return result ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Ejecuta calibración del acelerómetro.
  /// Retorna offsets {x, y, z} para compensación de bias.
  Future<Map<String, double>?> calibrateAccelerometer() async {
    try {
      final result = await _accelerometerChannel.invokeMethod<Map>(
        ChannelConstants.methodCalibrate,
      );
      return result?.map((key, value) => MapEntry(key as String, (value as num).toDouble()));
    } on MissingPluginException {
      return null;
    }
  }

  /// Retorna información del sensor del dispositivo.
  Future<Map<String, dynamic>?> getDeviceSensorInfo() async {
    try {
      final result = await _accelerometerChannel.invokeMethod<Map>(
        ChannelConstants.methodGetSensorInfo,
      );
      return result?.cast<String, dynamic>();
    } on MissingPluginException {
      return null;
    }
  }

  /// Stream continuo de datos del acelerómetro a alta frecuencia.
  Stream<Map<String, double>> get accelerometerStream {
    return _accelerometerStreamChannel
        .receiveBroadcastStream()
        .map((event) {
      final data = Map<String, dynamic>.from(event as Map);
      return {
        'x': (data['x'] as num).toDouble(),
        'y': (data['y'] as num).toDouble(),
        'z': (data['z'] as num).toDouble(),
        'timestamp': (data['timestamp'] as num).toDouble(),
      };
    });
  }

  // ═══════════════════════════════════════════════════════════
  //  CONTROL DE DISPOSITIVO (Alarmas)
  // ═══════════════════════════════════════════════════════════

  /// Establece el volumen del dispositivo (0-100).
  Future<void> setVolume(int volumePercent) async {
    try {
      await _deviceControlChannel.invokeMethod(
        ChannelConstants.methodSetVolume,
        {'volume': volumePercent.clamp(0, 100)},
      );
    } on MissingPluginException {
      // Canal nativo no disponible
    }
  }

  /// Establece un patrón de vibración personalizado.
  ///
  /// [pattern] lista de duraciones en ms, alternando vibración/pausa.
  /// Ejemplo: [0, 500, 200, 500] → pausa 0ms, vibrar 500ms, pausa 200ms, vibrar 500ms.
  Future<void> setVibrationPattern(List<int> pattern) async {
    try {
      await _deviceControlChannel.invokeMethod(
        ChannelConstants.methodSetVibration,
        {'pattern': pattern},
      );
    } on MissingPluginException {
      // Canal nativo no disponible
    }
  }

  /// Enciende la pantalla del dispositivo (WakeUp).
  Future<void> wakeScreen() async {
    try {
      await _deviceControlChannel.invokeMethod(
        ChannelConstants.methodWakeScreen,
      );
    } on MissingPluginException {
      // Canal nativo no disponible
    }
  }

  /// Activa la sirena de alarma con nivel de severidad.
  Future<void> activateSiren(int severityLevel) async {
    try {
      await _deviceControlChannel.invokeMethod(
        ChannelConstants.methodActivateSiren,
        {'severityLevel': severityLevel},
      );
    } on MissingPluginException {
      // Canal nativo no disponible
    }
  }

  /// Desactiva la sirena de alarma.
  Future<void> deactivateSiren() async {
    try {
      await _deviceControlChannel.invokeMethod(
        ChannelConstants.methodDeactivateSiren,
      );
    } on MissingPluginException {
      // Canal nativo no disponible
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  SMS FALLBACK
  // ═══════════════════════════════════════════════════════════

  /// Envía un SMS silencioso con telemetría comprimida.
  Future<bool> sendSilentSms({
    required String phoneNumber,
    required String payload,
  }) async {
    try {
      final result = await _smsFallbackChannel.invokeMethod<bool>(
        'sendSilentSms',
        {
          'phoneNumber': phoneNumber,
          'payload': payload,
        },
      );
      return result ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  CELL BROADCAST
  // ═══════════════════════════════════════════════════════════

  /// Stream de mensajes Cell Broadcast interceptados.
  Stream<Map<String, String>> get cellBroadcastStream {
    return _cellBroadcastStreamChannel
        .receiveBroadcastStream()
        .map((event) {
      final data = Map<String, dynamic>.from(event as Map);
      return data.map((key, value) => MapEntry(key, value.toString()));
    });
  }
}
