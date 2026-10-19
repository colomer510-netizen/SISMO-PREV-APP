import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Pasarela a Internet (Gateway Relay) para Nodos Aislados
/// Cuando un teléfono con conexión recibe una alerta P2P de un vecino desconectado,
/// la retransmite de inmediato al servidor central SISMO-PREV o a Supabase Realtime.
class CloudGatewayRelayDatasource {

  CloudGatewayRelayDatasource({
    this.serverUrl = 'http://10.0.2.2:8000',
    this.supabaseUrl,
    this.supabaseAnonKey,
  });
  final String serverUrl;
  final String? supabaseUrl;
  final String? supabaseAnonKey;

  Future<bool> relayAlert(Map<String, dynamic> alertPayload) async {
    final originalNode = alertPayload['node_id'] ?? alertPayload['device_id'] ?? 'NODO_VECINO';

    // 1. Intentar servidor central SISMO-PREV
    try {
      final res = await http.post(
        Uri.parse('$serverUrl/api/alert'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(alertPayload),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200 || res.statusCode == 201) {
        debugPrint('✅ Pasarela SISMO-PREV: Alerta de [$originalNode] subida a la nube exitosamente.');
        return true;
      }
    } catch (_) {}

    // 2. Respaldo Supabase Realtime (si está configurado)
    if (supabaseUrl != null && supabaseAnonKey != null) {
      try {
        final res = await http.post(
          Uri.parse('$supabaseUrl/rest/v1/alerts'),
          headers: {
            'Content-Type': 'application/json',
            'apikey': supabaseAnonKey!,
            'Authorization': 'Bearer $supabaseAnonKey',
            'Prefer': 'return=minimal',
          },
          body: jsonEncode({
            'node_id': originalNode,
            'timestamp': alertPayload['timestamp'] ?? (DateTime.now().millisecondsSinceEpoch / 1000.0),
            'alert_type': alertPayload['alert_type'] ?? 'SEISMIC_WAVE_P',
            'severity': alertPayload['severity'] ?? 'EXTREME',
            'pga': alertPayload['pga'] ?? 0.0,
            'latitude': alertPayload['latitude'],
            'longitude': alertPayload['longitude'],
            'relayed_by_gateway': true,
          }),
        ).timeout(const Duration(seconds: 4));

        if (res.statusCode == 200 || res.statusCode == 201) {
          debugPrint('✅ Pasarela Supabase: Alerta de [$originalNode] transmitida a Postgres Realtime.');
          return true;
        }
      } catch (_) {}
    }

    return false;
  }
}
