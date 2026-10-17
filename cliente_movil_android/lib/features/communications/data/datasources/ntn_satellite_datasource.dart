// ============================================================================
// SismoGuard — Datasource: Conectividad Satelital NTN
// ============================================================================
// Interfaz abstracta para futuras redes no terrestres (NTN) según
// el estándar 3GPP Release 17 para conexiones directas al satélite.
//
// Este datasource implementa el patrón Strategy como parte de la
// cadena de fallback de comunicaciones:
//
// Prioridad: TCP/IP → BLE Mesh → LoRa → SMS → NTN Satelital
//
// Referencia: 3GPP TS 38.821 (NTN), Release 17
// ============================================================================

import 'dart:async';

/// Estado de la conexión satelital NTN.
enum NtnConnectionState {
  /// Hardware NTN no disponible en este dispositivo.
  unavailable,

  /// NTN disponible pero no conectado.
  available,

  /// Buscando enlace satelital.
  connecting,

  /// Enlace satelital establecido.
  connected,

  /// Error de conexión satelital.
  error,
}

/// Tipo de servicio NTN disponible.
enum NtnServiceType {
  /// Servicio de emergencia SOS (mínimo, solo ubicación).
  emergencySos,

  /// Mensajería satelital básica (texto corto).
  messaging,

  /// Datos satelitales de banda estrecha (NB-IoT over NTN).
  narrowbandData,

  /// No disponible.
  none,
}

/// Interfaz del datasource NTN satelital.
abstract class NtnSatelliteDatasource {
  /// Verifica si el dispositivo soporta NTN.
  Future<bool> isNtnAvailable();

  /// Intenta establecer conexión satelital.
  Future<bool> connect();

  /// Desconecta el enlace satelital.
  Future<void> disconnect();

  /// Envía un mensaje de emergencia via satélite.
  Future<bool> sendEmergencyMessage({
    required double latitude,
    required double longitude,
    required String message,
  });

  /// Obtiene el tipo de servicio NTN disponible.
  Future<NtnServiceType> getAvailableServiceType();

  /// Estado de conexión actual.
  NtnConnectionState get connectionState;

  /// Stream de estado de conexión.
  Stream<NtnConnectionState> get stateStream;
}

/// Implementación stub del datasource NTN satelital.
///
/// 3GPP Release 17 define el soporte NTN para:
/// - Redes LEO (Low Earth Orbit) como Starlink, AST SpaceMobile
/// - NB-IoT sobre satélite para IoT de emergencia
/// - Extensión de cobertura celular en zonas sin torres base
///
/// Compatibilidad futura con:
/// - Qualcomm Snapdragon Satellite (via Iridium)
/// - Samsung/Apple satellite SOS
/// - MediaTek NTN support
class NtnSatelliteDatasourceImpl implements NtnSatelliteDatasource {
  NtnConnectionState _connectionState = NtnConnectionState.unavailable;

  final StreamController<NtnConnectionState> _stateController =
      StreamController<NtnConnectionState>.broadcast();

  @override
  NtnConnectionState get connectionState => _connectionState;

  @override
  Stream<NtnConnectionState> get stateStream => _stateController.stream;

  @override
  Future<bool> isNtnAvailable() async {
    // TODO: Verificar soporte NTN del dispositivo:
    //
    // 1. Verificar chipset del modem (Qualcomm X75+, MediaTek D9200+)
    // 2. Verificar APIs de Android 15+ para satellite connectivity
    // 3. Verificar disponibilidad de SatelliteManager API
    //
    // Android 15 introduce:
    // - SatelliteManager.requestEnabled()
    // - SatelliteManager.requestIsSupported()
    // - SatelliteManager.startSatelliteTransmissionUpdates()

    return false; // No disponible en la mayoría de dispositivos actuales
  }

  @override
  Future<bool> connect() async {
    final available = await isNtnAvailable();
    if (!available) {
      _updateState(NtnConnectionState.unavailable);
      return false;
    }

    _updateState(NtnConnectionState.connecting);

    // TODO: Iniciar búsqueda de enlace satelital
    // Requiere vista despejada del cielo (outdoor)

    _updateState(NtnConnectionState.error);
    return false;
  }

  @override
  Future<void> disconnect() async {
    _updateState(NtnConnectionState.unavailable);
  }

  @override
  Future<bool> sendEmergencyMessage({
    required double latitude,
    required double longitude,
    required String message,
  }) async {
    if (_connectionState != NtnConnectionState.connected) {
      return false;
    }

    // TODO: Enviar mensaje de emergencia via NTN
    // Formato: Minimizar payload (NTN tiene ancho de banda muy limitado)
    // Priorizar: lat, lon, timestamp, tipo de emergencia

    return false;
  }

  @override
  Future<NtnServiceType> getAvailableServiceType() async {
    if (_connectionState == NtnConnectionState.unavailable) {
      return NtnServiceType.none;
    }

    // TODO: Consultar capacidades del servicio NTN disponible
    return NtnServiceType.none;
  }

  void _updateState(NtnConnectionState newState) {
    _connectionState = newState;
    _stateController.add(newState);
  }

  void dispose() {
    _stateController.close();
  }
}

/// Selector de canal de comunicación con fallback automático.
///
/// Implementa el patrón Chain of Responsibility para seleccionar
/// el mejor canal de comunicación disponible.
///
/// Orden de prioridad:
/// 1. TCP/IP (Internet normal)
/// 2. BLE Mesh (Bridgefy)
/// 3. LoRa (Meshtastic)
/// 4. SMS (Fallback silencioso)
/// 5. NTN Satelital (Futuro)
class CommunicationChannelSelector {
  /// Retorna el nombre del canal de mayor prioridad disponible.
  ///
  /// [hasInternet] - TCP/IP disponible
  /// [hasBle] - BLE Mesh activo
  /// [hasLoRa] - Nodo LoRa conectado
  /// [hasSms] - Permiso SMS concedido
  /// [hasNtn] - Enlace satelital disponible
  static String selectBestChannel({
    required bool hasInternet,
    required bool hasBle,
    required bool hasLoRa,
    required bool hasSms,
    required bool hasNtn,
  }) {
    if (hasInternet) return 'tcp_ip';
    if (hasBle) return 'ble_mesh';
    if (hasLoRa) return 'lora_meshtastic';
    if (hasSms) return 'sms_fallback';
    if (hasNtn) return 'ntn_satellite';
    return 'none';
  }

  /// Retorna todos los canales disponibles ordenados por prioridad.
  static List<String> getAvailableChannels({
    required bool hasInternet,
    required bool hasBle,
    required bool hasLoRa,
    required bool hasSms,
    required bool hasNtn,
  }) {
    final channels = <String>[];
    if (hasInternet) channels.add('tcp_ip');
    if (hasBle) channels.add('ble_mesh');
    if (hasLoRa) channels.add('lora_meshtastic');
    if (hasSms) channels.add('sms_fallback');
    if (hasNtn) channels.add('ntn_satellite');
    return channels;
  }
}
