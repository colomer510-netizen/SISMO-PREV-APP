// ============================================================================
// SismoGuard — Constantes Globales de la Aplicación
// ============================================================================

/// Constantes globales de configuración para SismoGuard.
abstract class AppConstants {
  AppConstants._();

  // ─── Identificación de la App ───
  static const String appName = 'SismoGuard';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // ─── Detección Sísmica ───
  /// Tasa de muestreo del acelerómetro en Hz.
  static const int accelerometerSampleRateHz = 50;

  /// Intervalo entre muestras en milisegundos (1000 / 50 = 20ms).
  static const int sampleIntervalMs = 1000 ~/ accelerometerSampleRateHz;

  /// Duración de la ventana STA (Short-Term Average) en segundos.
  static const double staWindowSeconds = 1.0;

  /// Duración de la ventana LTA (Long-Term Average) en segundos.
  static const double ltaWindowSeconds = 20.0;

  /// Umbral de trigger STA/LTA (ratio para declarar evento sísmico).
  static const double staLtaTriggerThreshold = 3.5;

  /// Umbral de detrigger STA/LTA (ratio para finalizar evento).
  static const double staLtaDetriggerThreshold = 1.5;

  /// Frecuencias del filtro pasa-bandas en Hz.
  static const double bandpassLowFreqHz = 1.0;
  static const double bandpassHighFreqHz = 20.0;

  // ─── CNN Classifier ───
  /// Nombre del archivo del modelo TFLite.
  static const String cnnModelAsset = 'assets/models/seismic_classifier.tflite';

  /// Duración de la ventana de análisis CNN en segundos.
  static const double cnnWindowSeconds = 2.0;

  /// Umbral de confianza para clasificar como sismo real.
  static const double cnnConfidenceThreshold = 0.75;

  // ─── Comunicaciones ───
  /// Placeholder para la API Key de Bridgefy.
  /// IMPORTANTE: Reemplazar con la key real obtenida en https://bridgefy.me
  static const String bridgefyApiKey = 'YOUR_BRIDGEFY_API_KEY_HERE';

  /// Número de teléfono del backend para SMS de contingencia.
  static const String smsBackendNumber = '+0000000000';

  /// Prefijo del protocolo de telemetría SMS compacto.
  static const String smsTelemetryPrefix = 'SG';

  /// Longitud máxima del payload SMS (160 caracteres estándar).
  static const int smsMaxPayloadLength = 160;

  // ─── Mapas Offline ───
  /// Nombre del archivo MBTiles por defecto.
  static const String defaultMbtilesFile = 'sismoguard_map.mbtiles';

  /// Nombre del archivo de estilo JSON para MapLibre.
  static const String defaultMapStyle = 'assets/styles/offline_style.json';

  // ─── Timeouts y Reintentos ───
  /// Timeout para conexiones de red en segundos.
  static const int networkTimeoutSeconds = 30;

  /// Número máximo de reintentos para operaciones de red.
  static const int maxNetworkRetries = 3;

  /// Intervalo entre reintentos en milisegundos.
  static const int retryIntervalMs = 2000;
}
