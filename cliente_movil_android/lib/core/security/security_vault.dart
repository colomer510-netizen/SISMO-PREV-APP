import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Bóveda Criptográfica y de Privacidad para SISMO-PREV
/// Protege la red comunitaria contra ataques Man-In-The-Middle, spoofing y rastreo.
class SecurityVault {
  static const String _communityKey = 'SISMOPREV_COMMUNITY_SECURE_KEY_2026';

  /// Genera un Identificador Temporal Efímero (Pseudo-anónimo) rotativo diario
  static String generateEphemeralNodeId(String permanentHardwareId) {
    final now = DateTime.now();
    final dayEpoch = '${now.year}-${now.month}-${now.day}';
    final rawString = '$permanentHardwareId:$_communityKey:$dayEpoch';
    final hash = sha256.convert(utf8.encode(rawString)).toString();
    return 'SISMO-${hash.substring(0, 8).toUpperCase()}';
  }

  /// Ofuscación de Privacidad Geoespacial (Anti-Doxing):
  /// Trunca coordenadas a cuadrantes de ~200m para no exponer la vivienda del usuario.
  static Map<String, double> anonymizeCoordinates(double lat, double lon) {
    final double fLat = double.parse(lat.toStringAsFixed(3));
    final double fLon = double.parse(lon.toStringAsFixed(3));
    return {'lat': fLat, 'lon': fLon};
  }

  /// Sella criptográficamente una alerta con HMAC-SHA256
  static String signAndSealPayload(Map<String, dynamic> rawPayload) {
    final jsonStr = jsonEncode(rawPayload);
    final hmac = Hmac(sha256, utf8.encode(_communityKey));
    final digest = hmac.convert(utf8.encode(jsonStr));

    final sealedMessage = {
      'payload': rawPayload,
      'signature': digest.toString(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    return jsonEncode(sealedMessage);
  }

  /// Valida la autenticidad y frescura del paquete entrante
  static bool verifyAndUnsealPayload(String jsonEnvelope, {required Function(Map<String, dynamic>) onValid}) {
    try {
      final decoded = jsonDecode(jsonEnvelope) as Map<String, dynamic>;
      final rawPayload = decoded['payload'] as Map<String, dynamic>;
      final signature = decoded['signature'] as String;
      final ts = decoded['timestamp'] as int;

      // Descartar ataques de repetición (>60s)
      final diff = DateTime.now().millisecondsSinceEpoch - ts;
      if (diff > 60000) return false;

      final hmac = Hmac(sha256, utf8.encode(_communityKey));
      final expectedDigest = hmac.convert(utf8.encode(jsonEncode(rawPayload))).toString();

      if (expectedDigest == signature) {
        onValid(rawPayload);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
