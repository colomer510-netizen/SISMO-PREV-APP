import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

/// Servicio de Telemetría para conectar el teléfono con el Servidor Central SismoGuard.
class TelemetryService {
  TelemetryService({
    required this.serverBaseUrl,
    required this.nodeId,
    this.place = 'Sede Universitaria - Muro Norte',
  });

  final String serverBaseUrl;
  final String nodeId;
  final String place;

  Timer? _heartbeatTimer;
  bool _isBroadcasting = false;

  /// Inicia el envío continuo de latidos (Heartbeat) al servidor cada 2 segundos
  void startHeartbeat({
    required double Function() getCurrentPga,
    required double Function() getCurrentRatio,
    required bool Function() getIsTriggered,
  }) {
    if (_isBroadcasting) return;
    _isBroadcasting = true;

    _heartbeatTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      final pga = getCurrentPga();
      final ratio = getCurrentRatio();
      final isTriggered = getIsTriggered();

      await sendTelemetry(
        pga: pga,
        staLtaRatio: ratio,
        isTriggered: isTriggered,
      );
    });
  }

  /// Envía un paquete de telemetría inmediato (usado en ráfagas al detectar Onda P)
  Future<bool> sendTelemetry({
    required double pga,
    required double staLtaRatio,
    required bool isTriggered,
  }) async {
    final url = Uri.parse('$serverBaseUrl/api/telemetry');
    final payload = {
      'node_id': nodeId,
      'place': place,
      'lat': 12.1364,
      'lng': -86.2514,
      'pga': pga,
      'sta_lta_ratio': staLtaRatio,
      'is_triggered': isTriggered,
      'battery': 95,
    };

    try {
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 2));

      return resp.statusCode == 200;
    } catch (e) {
      // Offline-First: si no hay conexión al servidor central, conmuta a BLE Mesh/SMS
      return false;
    }
  }

  void stop() {
    _heartbeatTimer?.cancel();
    _isBroadcasting = false;
  }
}
