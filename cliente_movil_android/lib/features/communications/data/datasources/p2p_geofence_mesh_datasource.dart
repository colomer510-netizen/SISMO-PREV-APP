import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../../core/security/security_vault.dart';

/// Malla P2P con Cortafuegos Geofencing & Límite de Saltos (TTL)
/// Previene la propagación epidémica de alertas fuera del radio de impacto.
class P2pGeofenceMeshDatasource {
  static const int broadcastPort = 42424;
  static const int defaultMaxHops = 3;
  static const double defaultMaxRadiusKm = 15.0;

  RawDatagramSocket? _broadcastSocket;
  bool _isRunning = false;
  final Set<String> _seenPacketFingerprints = {};

  Function(Map<String, dynamic>)? onAlertReceived;

  bool get isRunning => _isRunning;

  Future<void> start({double? currentLat, double? currentLon}) async {
    if (_isRunning) return;

    try {
      _broadcastSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        broadcastPort,
        reuseAddress: true,
      );
      _broadcastSocket?.broadcastEnabled = true;
      _isRunning = true;

      _broadcastSocket?.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _broadcastSocket?.receive();
          if (datagram != null) {
            final rawMessage = utf8.decode(datagram.data);
            SecurityVault.verifyAndUnsealPayload(
              rawMessage,
              onValid: (validPayload) {
                _processPacket(validPayload, currentLat: currentLat, currentLon: currentLon);
              },
            );
          }
        }
      });
    } catch (e) {
      debugPrint('Error iniciando P2pGeofenceMeshDatasource: $e');
      _isRunning = false;
    }
  }

  void _processPacket(Map<String, dynamic> payload, {double? currentLat, double? currentLon}) {
    final packetId = payload['packet_id'] as String? ?? "${payload['node_id']}_${payload['timestamp']}";

    // 1. Deduplicación
    if (_seenPacketFingerprints.contains(packetId)) return;
    _seenPacketFingerprints.add(packetId);
    if (_seenPacketFingerprints.length > 500) {
      _seenPacketFingerprints.remove(_seenPacketFingerprints.first);
    }

    // 2. Cortafuegos Geográfico (Haversine)
    final originLat = payload['latitude'] as double?;
    final originLon = payload['longitude'] as double?;
    final maxRadiusKm = (payload['impact_radius_km'] as num?)?.toDouble() ?? defaultMaxRadiusKm;

    if (currentLat != null && currentLon != null && originLat != null && originLon != null) {
      final distanceKm = _haversineDistance(currentLat, currentLon, originLat, originLon);
      if (distanceKm > maxRadiusKm) {
        debugPrint('🛑 Alerta fuera de radio ($distanceKm km > $maxRadiusKm km). Freno geodésico activado.');
        return;
      }
    }

    // 3. Notificar a la aplicación y al Gateway Bridge
    onAlertReceived?.call(payload);

    // 4. Decremento de TTL y Retransmisión
    final int currentHops = (payload['hops'] as int?) ?? 0;
    final int maxHops = (payload['max_hops'] as int?) ?? defaultMaxHops;

    if (currentHops < maxHops) {
      payload['hops'] = currentHops + 1;
      _retransmit(payload);
    }
  }

  void _retransmit(Map<String, dynamic> payload) {
    try {
      final envelope = SecurityVault.signAndSealPayload(payload);
      final bytes = utf8.encode(envelope);
      _broadcastSocket?.send(bytes, InternetAddress('255.255.255.255'), broadcastPort);
    } catch (_) {}
  }

  Future<void> broadcastAlert(Map<String, dynamic> alert, {double impactRadiusKm = defaultMaxRadiusKm}) async {
    if (_broadcastSocket == null || !_isRunning) return;

    try {
      final packetId = "PKT_${DateTime.now().millisecondsSinceEpoch}_${alert['node_id']}";
      _seenPacketFingerprints.add(packetId);

      alert['packet_id'] = packetId;
      alert['hops'] = 1;
      alert['max_hops'] = defaultMaxHops;
      alert['impact_radius_km'] = impactRadiusKm;

      if (alert.containsKey('latitude') && alert.containsKey('longitude')) {
        final anon = SecurityVault.anonymizeCoordinates(
          alert['latitude'] as double,
          alert['longitude'] as double,
        );
        alert['latitude'] = anon['lat'];
        alert['longitude'] = anon['lon'];
      }

      final envelope = SecurityVault.signAndSealPayload(alert);
      final bytes = utf8.encode(envelope);
      _broadcastSocket?.send(bytes, InternetAddress('255.255.255.255'), broadcastPort);
    } catch (e) {
      debugPrint('Error transmitiendo P2P Alert: $e');
    }
  }

  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;
    final double dLat = (lat2 - lat1) * (pi / 180.0);
    final double dLon = (lon2 - lon1) * (pi / 180.0);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) * cos(lat2 * (pi / 180.0)) *
        sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  void stop() {
    _broadcastSocket?.close();
    _broadcastSocket = null;
    _isRunning = false;
  }
}
