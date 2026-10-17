// ============================================================================
// SismoGuard — Datasource: Protocolo Meshtastic (LoRa)
// ============================================================================
// Capa de servicio preparada para vincularse via Bluetooth a nodos de
// hardware LoRa externos que ejecutan el protocolo Meshtastic.
//
// Meshtastic permite enlaces de radiofrecuencia de larga distancia
// (hasta 10+ km en línea de vista) usando chips LoRa económicos.
//
// Referencia: https://meshtastic.org/docs/
// ============================================================================

import 'dart:async';

/// Estado de conexión con el nodo Meshtastic.
enum MeshtasticConnectionState {
  /// No conectado a ningún nodo.
  disconnected,

  /// Buscando nodos LoRa cercanos via BLE.
  scanning,

  /// Conectado a un nodo LoRa.
  connected,

  /// Error de conexión.
  error,
}

/// Información de un nodo Meshtastic descubierto.
class MeshtasticNode {
  const MeshtasticNode({
    required this.deviceId,
    required this.deviceName,
    this.rssi,
    this.firmwareVersion,
    this.batteryLevel,
  });

  final String deviceId;
  final String deviceName;
  final int? rssi;
  final String? firmwareVersion;
  final int? batteryLevel;
}

/// Mensaje recibido/enviado via Meshtastic LoRa.
class LoRaMessage {
  const LoRaMessage({
    required this.id,
    required this.payload,
    required this.timestamp,
    this.senderId,
    this.hopCount = 0,
    this.snr,
    this.rssi,
  });

  final String id;
  final String payload;
  final DateTime timestamp;
  final String? senderId;
  final int hopCount;
  final double? snr; // Signal-to-Noise Ratio
  final int? rssi;   // Received Signal Strength Indicator
}

/// Interfaz del datasource Meshtastic.
abstract class MeshtasticDatasource {
  /// Escanea y conecta al nodo LoRa más cercano via BLE.
  Future<bool> connectToNode(String deviceId);

  /// Desconecta del nodo LoRa actual.
  Future<void> disconnect();

  /// Envía un mensaje via la red LoRa.
  Future<bool> sendMessage(String payload);

  /// Envía una alerta de emergencia (prioridad máxima).
  Future<bool> sendEmergencyAlert(Map<String, dynamic> alertData);

  /// Escanea nodos Meshtastic cercanos.
  Future<List<MeshtasticNode>> scanForNodes();

  /// Estado de conexión actual.
  MeshtasticConnectionState get connectionState;

  /// Stream de mensajes recibidos del LoRa mesh.
  Stream<LoRaMessage> get messageStream;

  /// Stream de estado de conexión.
  Stream<MeshtasticConnectionState> get stateStream;
}

/// Implementación stub del datasource Meshtastic.
///
/// Esta implementación prepara toda la interfaz para la integración
/// futura con nodos LoRa Meshtastic via BLE. Los UUIDs de servicio
/// y características del protocolo Meshtastic están predefinidos.
class MeshtasticDatasourceImpl implements MeshtasticDatasource {
  // ─── UUIDs del Protocolo Meshtastic BLE ───
  // Referencia: https://meshtastic.org/docs/development/device/client-api
  static const String serviceUuid = '6ba1b218-15a8-461f-9fa8-5dcae273eafd';
  static const String toRadioCharUuid = 'f75c76d2-129e-4dad-a1dd-7866124401e7';
  static const String fromRadioCharUuid = '8ba2bcc2-ee02-4a62-8014-a5684d6c1cb5';
  static const String fromNumCharUuid = 'ed9da18c-a800-4f66-a670-aa7547de5ee1';

  // ─── Estado ───
  MeshtasticConnectionState _connectionState =
      MeshtasticConnectionState.disconnected;
  String? _connectedNodeId;

  // ─── Streams ───
  final StreamController<LoRaMessage> _messageController =
      StreamController<LoRaMessage>.broadcast();
  final StreamController<MeshtasticConnectionState> _stateController =
      StreamController<MeshtasticConnectionState>.broadcast();

  @override
  MeshtasticConnectionState get connectionState => _connectionState;

  @override
  Stream<LoRaMessage> get messageStream => _messageController.stream;

  @override
  Stream<MeshtasticConnectionState> get stateStream => _stateController.stream;

  @override
  Future<List<MeshtasticNode>> scanForNodes() async {
    _updateState(MeshtasticConnectionState.scanning);

    // TODO: Implementar escaneo BLE buscando dispositivos que
    // expongan el servicio UUID de Meshtastic.
    //
    // Pasos:
    // 1. Usar flutter_blue_plus para escanear BLE
    // 2. Filtrar por serviceUuid
    // 3. Leer RSSI y nombre del dispositivo
    // 4. Retornar lista de nodos encontrados

    _updateState(MeshtasticConnectionState.disconnected);
    return [];
  }

  @override
  Future<bool> connectToNode(String deviceId) async {
    try {
      _updateState(MeshtasticConnectionState.scanning);

      // TODO: Implementar conexión BLE al nodo Meshtastic:
      //
      // 1. Conectar al dispositivo BLE por deviceId
      // 2. Descubrir servicios y características
      // 3. Suscribirse a fromRadioCharUuid para recibir mensajes
      // 4. Usar toRadioCharUuid para enviar mensajes
      // 5. Leer fromNumCharUuid para notificaciones

      _connectedNodeId = deviceId;
      _updateState(MeshtasticConnectionState.connected);
      return true;
    } catch (e) {
      _updateState(MeshtasticConnectionState.error);
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    // TODO: Desconectar BLE y limpiar suscripciones
    _connectedNodeId = null;
    _updateState(MeshtasticConnectionState.disconnected);
  }

  @override
  Future<bool> sendMessage(String payload) async {
    if (_connectionState != MeshtasticConnectionState.connected) {
      return false;
    }

    // TODO: Serializar mensaje en formato protobuf de Meshtastic
    // y escribir en toRadioCharUuid

    return false; // Stub
  }

  @override
  Future<bool> sendEmergencyAlert(Map<String, dynamic> alertData) async {
    if (_connectionState != MeshtasticConnectionState.connected) {
      return false;
    }

    // TODO: Crear un paquete de emergencia Meshtastic con:
    // - Canal 0 (canal principal)
    // - Prioridad máxima
    // - Datos comprimidos de la alerta

    return false; // Stub
  }

  void _updateState(MeshtasticConnectionState newState) {
    _connectionState = newState;
    _stateController.add(newState);
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _stateController.close();
  }
}
