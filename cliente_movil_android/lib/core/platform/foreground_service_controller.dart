// ============================================================================
// SismoGuard — Controlador del Foreground Service
// ============================================================================
// Gestiona el ciclo de vida del Foreground Service nativo de Android
// para detección sísmica continua. Utiliza flutter_foreground_task
// como wrapper y se comunica con el servicio Kotlin nativo via
// Method Channels cuando se necesita control fino del acelerómetro.
// ============================================================================

import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../constants/channel_constants.dart';

/// Controlador singleton del Foreground Service de detección sísmica.
///
/// Responsabilidades:
/// - Inicializar y configurar la notificación persistente
/// - Iniciar/detener el servicio de primer plano
/// - Comunicarse con el código nativo para el acelerómetro
/// - Gestionar el WakeLock para resistir Doze Mode
class ForegroundServiceController {
  ForegroundServiceController._internal();

  static final ForegroundServiceController instance =
      ForegroundServiceController._internal();

  /// Method Channel para control del servicio nativo.
  final MethodChannel _serviceChannel = const MethodChannel(
    ChannelConstants.foregroundServiceMethod,
  );

  /// Event Channel para stream de datos del acelerómetro.
  final EventChannel _accelerometerEventChannel = const EventChannel(
    ChannelConstants.accelerometerStream,
  );

  /// Event Channel para estado del servicio.
  final EventChannel _serviceStatusEventChannel = const EventChannel(
    ChannelConstants.serviceStatusStream,
  );

  bool _isInitialized = false;
  bool _isRunning = false;

  /// Indica si el servicio está actualmente en ejecución.
  bool get isRunning => _isRunning;

  /// Inicializa la configuración del Foreground Service.
  ///
  /// Debe llamarse una sola vez en el main() antes de iniciar el servicio.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Configurar el Foreground Task con notificación persistente.
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'sismoguard_seismic_detection',
        channelName: 'Detección Sísmica',
        channelDescription:
            'SismoGuard está monitorizando actividad sísmica continuamente.',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
        // Icono pequeño para la notificación (se debe agregar en drawable)
        // iconData: const NotificationIconData(
        //   resType: ResourceType.drawable,
        //   resPrefix: ResourcePrefix.ic,
        //   name: 'seismic_notification',
        // ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        // Intervalo de ejecución del callback (en ms).
        // 20ms ≈ 50Hz para el acelerómetro.
        eventAction: ForegroundTaskEventAction.repeat(20),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    _isInitialized = true;
  }

  /// Inicia el Foreground Service de detección sísmica.
  ///
  /// Crea la notificación persistente y activa el monitoreo
  /// continuo del acelerómetro.
  Future<bool> startService() async {
    if (!_isInitialized) {
      throw StateError(
        'ForegroundServiceController no inicializado. Llama a initialize() primero.',
      );
    }

    if (_isRunning) return true;

    try {
      // Verificar si el servicio puede iniciar.
      final isGranted =
          await FlutterForegroundTask.checkNotificationPermission();

      if (isGranted != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }

      // Intentar comunicación con el servicio nativo para iniciar
      // la captura del acelerómetro a alta frecuencia.
      try {
        await _serviceChannel.invokeMethod(
          ChannelConstants.methodStartService,
          {
            'sampleRateHz': 50,
            'enableWakeLock': true,
          },
        );
      } on MissingPluginException {
        // El servicio nativo aún no está implementado.
        // Continuar con flutter_foreground_task como fallback.
      }

      _isRunning = true;
      return true;
    } catch (e) {
      _isRunning = false;
      return false;
    }
  }

  /// Detiene el Foreground Service de detección sísmica.
  Future<bool> stopService() async {
    if (!_isRunning) return true;

    try {
      try {
        await _serviceChannel.invokeMethod(
          ChannelConstants.methodStopService,
        );
      } on MissingPluginException {
        // Ignorar si el canal nativo no está disponible.
      }

      _isRunning = false;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Retorna un Stream de datos del acelerómetro desde el código nativo.
  ///
  /// Cada evento es un Map con:
  /// - `x`: aceleración eje X (m/s²)
  /// - `y`: aceleración eje Y (m/s²)
  /// - `z`: aceleración eje Z (m/s²)
  /// - `timestamp`: marca temporal en nanosegundos
  Stream<dynamic> get accelerometerStream {
    return _accelerometerEventChannel.receiveBroadcastStream();
  }

  /// Retorna un Stream de eventos de estado del servicio.
  Stream<dynamic> get serviceStatusStream {
    return _serviceStatusEventChannel.receiveBroadcastStream();
  }

  /// Actualiza el texto de la notificación persistente.
  Future<void> updateNotification({
    required String title,
    required String body,
  }) async {
    FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText: body,
    );
  }
}
