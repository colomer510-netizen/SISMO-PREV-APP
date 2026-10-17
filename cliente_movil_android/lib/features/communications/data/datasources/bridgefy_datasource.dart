// ============================================================================
// SismoGuard — Datasource: Bridgefy BLE Mesh
// ============================================================================
// Integración con el Bridgefy SDK para comunicaciones P2P descentralizadas
// via Bluetooth Low Energy (BLE). Permite enviar y recibir alertas
// entre dispositivos cercanos SIN conexión a internet.
//
// Funcionalidad:
// - Inicialización del SDK con API Key
// - Broadcast de alertas a todos los nodos cercanos
// - Mensajes directos peer-to-peer
// - Gestión de perfiles de propagación (denso vs disperso)
// - Serialización de alertas CAP comprimidas para BLE
// ============================================================================

import 'dart:convert';
import 'dart:async';

import '../../../../core/constants/app_constants.dart';

/// Estado de la red de malla Bluetooth.
enum MeshNetworkState {
  /// SDK no inicializado.
  uninitialized,

  /// Inicializando SDK (requiere internet la primera vez).
  initializing,

  /// Red activa, escuchando y transmitiendo.
  active,

  /// Error en la inicialización o conexión.
  error,

  /// SDK detenido por el usuario.
  stopped,
}

/// Perfil de propagación de la red de malla.
enum MeshPropagationProfile {
  /// Alta densidad: muchos dispositivos cercanos.
  /// Reduce retransmisiones para evitar congestión.
  highDensity,

  /// Red dispersa: pocos dispositivos, distancias mayores.
  /// Aumenta el rango de retransmisión y tiempo de TTL.
  sparse,

  /// Perfil estándar balanceado.
  standard,
}

/// Mensaje recibido de la red de malla.
class MeshReceivedMessage {
  const MeshReceivedMessage({
    required this.messageId,
    required this.senderId,
    required this.payload,
    required this.receivedAt,
    required this.isBroadcast,
    this.hopCount = 0,
  });

  final String messageId;
  final String senderId;
  final Map<String, dynamic> payload;
  final DateTime receivedAt;
  final bool isBroadcast;
  final int hopCount;
}

/// Interfaz del datasource para comunicaciones BLE Mesh.
abstract class BridgefyDatasource {
  /// Inicializa el SDK de Bridgefy.
  Future<bool> initialize({String? apiKey});

  /// Inicia la red de malla.
  Future<bool> startMeshNetwork();

  /// Detiene la red de malla.
  Future<void> stopMeshNetwork();

  /// Envía un mensaje broadcast a todos los nodos cercanos.
  Future<bool> broadcastAlert(Map<String, dynamic> alertData);

  /// Envía un mensaje directo a un peer específico.
  Future<bool> sendDirectMessage(String peerId, Map<String, dynamic> data);

  /// Estado actual de la red.
  MeshNetworkState get networkState;

  /// Número de peers conectados.
  int get connectedPeersCount;

  /// Stream de mensajes recibidos de la red de malla.
  Stream<MeshReceivedMessage> get messageStream;

  /// Stream de cambios de estado de la red.
  Stream<MeshNetworkState> get stateStream;

  /// Configura el perfil de propagación.
  void setPropagationProfile(MeshPropagationProfile profile);
}

/// Implementación del datasource Bridgefy BLE Mesh.
class BridgefyDatasourceImpl implements BridgefyDatasource {
  BridgefyDatasourceImpl({String? apiKey})
      : _apiKey = apiKey ?? AppConstants.bridgefyApiKey;

  final String _apiKey;

  // ─── Estado Interno ───
  MeshNetworkState _networkState = MeshNetworkState.uninitialized;
  MeshPropagationProfile _propagationProfile = MeshPropagationProfile.standard;
  int _connectedPeers = 0;

  // ─── Streams ───
  final StreamController<MeshReceivedMessage> _messageController =
      StreamController<MeshReceivedMessage>.broadcast();
  final StreamController<MeshNetworkState> _stateController =
      StreamController<MeshNetworkState>.broadcast();

  // ─── Referencia al SDK ───
  // Bridgefy? _bridgefy; // Descomentar con el paquete bridgefy

  @override
  MeshNetworkState get networkState => _networkState;

  @override
  int get connectedPeersCount => _connectedPeers;

  @override
  Stream<MeshReceivedMessage> get messageStream => _messageController.stream;

  @override
  Stream<MeshNetworkState> get stateStream => _stateController.stream;

  // ═══════════════════════════════════════════════════════════
  //  INICIALIZACIÓN
  // ═══════════════════════════════════════════════════════════

  @override
  Future<bool> initialize({String? apiKey}) async {
    final key = apiKey ?? _apiKey;

    if (key == 'YOUR_BRIDGEFY_API_KEY_HERE' || key.isEmpty) {
      _updateState(MeshNetworkState.error);
      return false;
    }

    try {
      _updateState(MeshNetworkState.initializing);

      // ── Inicialización real del SDK Bridgefy ──
      // Descomentar cuando el SDK esté configurado:
      //
      // _bridgefy = Bridgefy(apiKey: key);
      //
      // await _bridgefy!.initialize(
      //   onStarted: () {
      //     _updateState(MeshNetworkState.active);
      //   },
      //   onStartError: (error) {
      //     _updateState(MeshNetworkState.error);
      //   },
      //   onDeviceConnected: (deviceId) {
      //     _connectedPeers++;
      //   },
      //   onDeviceDisconnected: (deviceId) {
      //     _connectedPeers = (_connectedPeers - 1).clamp(0, 9999);
      //   },
      //   onMessageReceived: (message) {
      //     _handleReceivedMessage(message, isBroadcast: false);
      //   },
      //   onBroadcastReceived: (message) {
      //     _handleReceivedMessage(message, isBroadcast: true);
      //   },
      // );

      // Stub: simular inicialización
      _updateState(MeshNetworkState.active);
      return true;
    } catch (e) {
      _updateState(MeshNetworkState.error);
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  CONTROL DE RED
  // ═══════════════════════════════════════════════════════════

  @override
  Future<bool> startMeshNetwork() async {
    if (_networkState == MeshNetworkState.uninitialized) {
      return false;
    }

    try {
      // _bridgefy?.start();
      _updateState(MeshNetworkState.active);
      return true;
    } catch (e) {
      _updateState(MeshNetworkState.error);
      return false;
    }
  }

  @override
  Future<void> stopMeshNetwork() async {
    // _bridgefy?.stop();
    _connectedPeers = 0;
    _updateState(MeshNetworkState.stopped);
  }

  // ═══════════════════════════════════════════════════════════
  //  ENVÍO DE MENSAJES
  // ═══════════════════════════════════════════════════════════

  @override
  Future<bool> broadcastAlert(Map<String, dynamic> alertData) async {
    if (_networkState != MeshNetworkState.active) return false;

    try {
      // Comprimir el payload para minimizar el tamaño BLE
      final compressedPayload = _compressAlertPayload(alertData);
      final payloadBytes = utf8.encode(jsonEncode(compressedPayload));

      // Verificar que el payload cabe en un mensaje BLE
      // Bridgefy maneja la fragmentación, pero es buena práctica minimizar
      if (payloadBytes.length > 2048) {
        // Payload demasiado grande, enviar versión resumida
        final minimalPayload = _createMinimalPayload(alertData);
        // await _bridgefy?.broadcast(jsonEncode(minimalPayload));
        return true;
      }

      // await _bridgefy?.broadcast(jsonEncode(compressedPayload));
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> sendDirectMessage(
    String peerId,
    Map<String, dynamic> data,
  ) async {
    if (_networkState != MeshNetworkState.active) return false;

    try {
      final payload = jsonEncode(data);
      // await _bridgefy?.send(peerId, payload);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  CONFIGURACIÓN DE PROPAGACIÓN
  // ═══════════════════════════════════════════════════════════

  @override
  void setPropagationProfile(MeshPropagationProfile profile) {
    _propagationProfile = profile;

    // Ajustar parámetros de Bridgefy según el perfil:
    switch (profile) {
      case MeshPropagationProfile.highDensity:
        // Reducir TTL y frecuencia de retransmisión
        // para evitar congestión en redes densas.
        break;
      case MeshPropagationProfile.sparse:
        // Aumentar TTL y rango de retransmisión
        // para alcanzar nodos distantes.
        break;
      case MeshPropagationProfile.standard:
        // Configuración balanceada por defecto.
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  PROCESAMIENTO INTERNO
  // ═══════════════════════════════════════════════════════════

  /// Comprime un payload de alerta para transmisión BLE eficiente.
  ///
  /// Formato comprimido: elimina campos verbosos del CAP y usa
  /// abreviaciones para los campos clave.
  Map<String, dynamic> _compressAlertPayload(Map<String, dynamic> alert) {
    return {
      't': 'SG_ALERT', // Tipo: SismoGuard Alert
      'v': 1,          // Versión del protocolo
      'id': alert['identifier'] ?? '',
      'st': alert['status'] ?? 'Actual',
      'ur': alert['urgency'] ?? 'Unknown',
      'sv': alert['severity'] ?? 'Unknown',
      'ct': alert['certainty'] ?? 'Unknown',
      'ev': alert['event'] ?? '',
      'hl': alert['headline'] ?? '',
      'ts': DateTime.now().millisecondsSinceEpoch,
      'lt': alert['latitude'],
      'ln': alert['longitude'],
    };
  }

  /// Crea un payload mínimo cuando el original es demasiado grande.
  Map<String, dynamic> _createMinimalPayload(Map<String, dynamic> alert) {
    return {
      't': 'SG_ALERT',
      'v': 1,
      'sv': alert['severity'] ?? 'Unknown',
      'ev': alert['event'] ?? '',
      'ts': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Procesa un mensaje recibido de la red de malla.
  void _handleReceivedMessage(dynamic rawMessage, {required bool isBroadcast}) {
    try {
      final data = jsonDecode(rawMessage.toString()) as Map<String, dynamic>;

      final message = MeshReceivedMessage(
        messageId: data['id']?.toString() ?? '',
        senderId: data['sender']?.toString() ?? '',
        payload: data,
        receivedAt: DateTime.now(),
        isBroadcast: isBroadcast,
      );

      _messageController.add(message);
    } catch (e) {
      // Mensaje malformado, ignorar
    }
  }

  /// Actualiza el estado y notifica a los listeners.
  void _updateState(MeshNetworkState newState) {
    _networkState = newState;
    _stateController.add(newState);
  }

  /// Libera recursos.
  void dispose() {
    // _bridgefy?.stop();
    _messageController.close();
    _stateController.close();
  }
}
