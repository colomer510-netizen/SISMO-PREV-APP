// ============================================================================
// SismoGuard — Datasource: SMS Fallback (Contingencia)
// ============================================================================
// Servicio de contingencia que empaqueta telemetría sísmica en un SMS
// y lo envía silenciosamente al backend cuando se pierde la conexión
// TCP/IP. Solo funciona en Android.
//
// Protocolo de telemetría compacta (max 160 caracteres):
// SG|<lat>|<lon>|<mag>|<timestamp>|<confidence>|<staLtaRatio>
//
// Ejemplo: SG|9.9281|-84.0907|4.2|1719417123|0.85|5.2
// ============================================================================

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/platform/native_bridge.dart';

/// Estado de conectividad para el fallback SMS.
enum ConnectivityFallbackState {
  /// Conexión TCP/IP disponible (no se necesita SMS).
  online,

  /// Sin conexión TCP/IP, SMS de contingencia activado.
  offline,

  /// Enviando SMS de contingencia.
  sendingSms,

  /// SMS enviado correctamente.
  smsSent,

  /// Error al enviar SMS.
  smsError,
}

/// Interfaz del datasource de SMS de contingencia.
abstract class SmsFallbackDatasource {
  /// Inicia el monitoreo de conectividad para activar el fallback.
  Future<void> startMonitoring();

  /// Detiene el monitoreo.
  void stopMonitoring();

  /// Empaqueta y envía telemetría sísmica via SMS.
  Future<bool> sendTelemetrySms({
    required double latitude,
    required double longitude,
    required double magnitude,
    required double confidence,
    required double staLtaRatio,
    String? additionalData,
  });

  /// Estado actual del fallback.
  ConnectivityFallbackState get state;

  /// Stream de cambios de estado.
  Stream<ConnectivityFallbackState> get stateStream;
}

/// Implementación del servicio SMS de contingencia.
class SmsFallbackDatasourceImpl implements SmsFallbackDatasource {
  SmsFallbackDatasourceImpl({
    required NativeBridge nativeBridge,
    Connectivity? connectivity,
    String? backendNumber,
  })  : _nativeBridge = nativeBridge,
        _connectivity = connectivity ?? Connectivity(),
        _backendNumber = backendNumber ?? AppConstants.smsBackendNumber;

  final NativeBridge _nativeBridge;
  final Connectivity _connectivity;
  final String _backendNumber;

  // ─── Estado ───
  ConnectivityFallbackState _state = ConnectivityFallbackState.online;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // ─── Streams ───
  final StreamController<ConnectivityFallbackState> _stateController =
      StreamController<ConnectivityFallbackState>.broadcast();

  // ─── Anti-flood: evitar envío masivo de SMS ───
  DateTime? _lastSmsSent;
  static const Duration _minSmsCooldown = Duration(minutes: 2);

  @override
  ConnectivityFallbackState get state => _state;

  @override
  Stream<ConnectivityFallbackState> get stateStream => _stateController.stream;

  // ═══════════════════════════════════════════════════════════
  //  MONITOREO DE CONECTIVIDAD
  // ═══════════════════════════════════════════════════════════

  @override
  Future<void> startMonitoring() async {
    // Verificar estado inicial
    final initialResults = await _connectivity.checkConnectivity();
    _evaluateConnectivity(initialResults);

    // Escuchar cambios de conectividad
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _evaluateConnectivity,
    );
  }

  @override
  void stopMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  /// Evalúa los resultados de conectividad y actualiza el estado.
  void _evaluateConnectivity(List<ConnectivityResult> results) {
    final hasInternet = results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);

    if (hasInternet) {
      _updateState(ConnectivityFallbackState.online);
    } else {
      _updateState(ConnectivityFallbackState.offline);
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  ENVÍO DE TELEMETRÍA SMS
  // ═══════════════════════════════════════════════════════════

  @override
  Future<bool> sendTelemetrySms({
    required double latitude,
    required double longitude,
    required double magnitude,
    required double confidence,
    required double staLtaRatio,
    String? additionalData,
  }) async {
    // ── Verificar cooldown para evitar flood ──
    if (_lastSmsSent != null) {
      final elapsed = DateTime.now().difference(_lastSmsSent!);
      if (elapsed < _minSmsCooldown) {
        return false; // Demasiado pronto para enviar otro SMS
      }
    }

    // ── Verificar que el número de backend está configurado ──
    if (_backendNumber == '+0000000000' || _backendNumber.isEmpty) {
      return false;
    }

    try {
      _updateState(ConnectivityFallbackState.sendingSms);

      // ── Empaquetar telemetría en formato compacto ──
      final payload = _packTelemetry(
        latitude: latitude,
        longitude: longitude,
        magnitude: magnitude,
        confidence: confidence,
        staLtaRatio: staLtaRatio,
        additionalData: additionalData,
      );

      // Verificar longitud del payload
      if (payload.length > AppConstants.smsMaxPayloadLength) {
        // Truncar datos adicionales si excede el límite
        final truncatedPayload = payload.substring(
          0,
          AppConstants.smsMaxPayloadLength,
        );
        final success = await _nativeBridge.sendSilentSms(
          phoneNumber: _backendNumber,
          payload: truncatedPayload,
        );

        _handleSmsResult(success);
        return success;
      }

      // Enviar SMS silencioso via canal nativo
      final success = await _nativeBridge.sendSilentSms(
        phoneNumber: _backendNumber,
        payload: payload,
      );

      _handleSmsResult(success);
      return success;
    } catch (e) {
      _updateState(ConnectivityFallbackState.smsError);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  PROTOCOLO DE TELEMETRÍA COMPACTA
  // ═══════════════════════════════════════════════════════════

  /// Empaqueta datos de telemetría en formato SMS compacto.
  ///
  /// Formato: SG|<lat>|<lon>|<mag>|<ts>|<conf>|<ratio>
  ///
  /// Cada campo se trunca para maximizar la información en 160 chars:
  /// - lat/lon: 4 decimales (precisión ~11m)
  /// - mag: 1 decimal
  /// - ts: epoch en segundos (no ms)
  /// - conf: 2 decimales
  /// - ratio: 1 decimal
  String _packTelemetry({
    required double latitude,
    required double longitude,
    required double magnitude,
    required double confidence,
    required double staLtaRatio,
    String? additionalData,
  }) {
    final buffer = StringBuffer();

    // Prefijo del protocolo
    buffer.write(AppConstants.smsTelemetryPrefix);
    buffer.write('|');

    // Coordenadas (4 decimales ≈ 11m de precisión)
    buffer.write(latitude.toStringAsFixed(4));
    buffer.write('|');
    buffer.write(longitude.toStringAsFixed(4));
    buffer.write('|');

    // Magnitud estimada (1 decimal)
    buffer.write(magnitude.toStringAsFixed(1));
    buffer.write('|');

    // Timestamp en segundos (Unix epoch)
    buffer.write(DateTime.now().millisecondsSinceEpoch ~/ 1000);
    buffer.write('|');

    // Confianza del CNN (2 decimales)
    buffer.write(confidence.toStringAsFixed(2));
    buffer.write('|');

    // Ratio STA/LTA (1 decimal)
    buffer.write(staLtaRatio.toStringAsFixed(1));

    // Datos adicionales si caben
    if (additionalData != null && additionalData.isNotEmpty) {
      final remaining =
          AppConstants.smsMaxPayloadLength - buffer.length - 1;
      if (remaining > 0) {
        buffer.write('|');
        buffer.write(additionalData.substring(
          0,
          remaining.clamp(0, additionalData.length),
        ));
      }
    }

    return buffer.toString();
  }

  /// Maneja el resultado del envío de SMS.
  void _handleSmsResult(bool success) {
    if (success) {
      _lastSmsSent = DateTime.now();
      _updateState(ConnectivityFallbackState.smsSent);
    } else {
      _updateState(ConnectivityFallbackState.smsError);
    }

    // Restaurar al estado de conectividad real después de 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      _updateState(_state == ConnectivityFallbackState.online
          ? ConnectivityFallbackState.online
          : ConnectivityFallbackState.offline);
    });
  }

  /// Actualiza el estado y notifica listeners.
  void _updateState(ConnectivityFallbackState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  /// Libera recursos.
  void dispose() {
    stopMonitoring();
    _stateController.close();
  }
}
