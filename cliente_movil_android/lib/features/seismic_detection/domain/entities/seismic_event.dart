// ============================================================================
// SismoGuard — Entidad: Evento Sísmico
// ============================================================================
// Entidad de dominio pura (sin dependencias de frameworks).
// Representa un evento sísmico detectado por el sistema.
// ============================================================================

import 'package:equatable/equatable.dart';

/// Clasificación del tipo de evento sísmico detectado.
enum SeismicEventType {
  /// Sismo confirmado (pasó STA/LTA + CNN).
  earthquake,

  /// Posible sismo (solo STA/LTA, CNN no disponible).
  possibleEarthquake,

  /// Actividad humana (CNN descartó como sismo).
  humanActivity,

  /// Indeterminado (datos insuficientes para clasificar).
  unknown,
}

/// Estado del análisis del evento.
enum SeismicAnalysisState {
  /// Trigger STA/LTA activado, pendiente de clasificación CNN.
  triggered,

  /// CNN procesando la ventana de datos.
  classifying,

  /// Clasificación completa.
  classified,

  /// Evento descartado por detrigger.
  dismissed,
}

/// Representa un evento sísmico detectado por el sistema de edge computing.
///
/// Cada evento captura:
/// - Datos del trigger STA/LTA (ratio, umbrales)
/// - Clasificación CNN (tipo, confianza)
/// - Posición geográfica (si está disponible)
/// - Marca temporal precisa
class SeismicEvent extends Equatable {
  const SeismicEvent({
    required this.id,
    required this.timestamp,
    required this.staLtaRatio,
    required this.triggerThreshold,
    this.eventType = SeismicEventType.unknown,
    this.analysisState = SeismicAnalysisState.triggered,
    this.cnnConfidence = 0.0,
    this.peakAcceleration = 0.0,
    this.latitude,
    this.longitude,
    this.durationMs = 0,
    this.sampleCount = 0,
  });

  /// Identificador único del evento.
  final String id;

  /// Marca temporal del momento de detección (UTC).
  final DateTime timestamp;

  /// Ratio STA/LTA al momento del trigger.
  final double staLtaRatio;

  /// Umbral de trigger configurado.
  final double triggerThreshold;

  /// Tipo de evento clasificado por CNN.
  final SeismicEventType eventType;

  /// Estado actual del análisis.
  final SeismicAnalysisState analysisState;

  /// Confianza del clasificador CNN (0.0 - 1.0).
  final double cnnConfidence;

  /// Aceleración pico detectada (m/s²).
  final double peakAcceleration;

  /// Latitud del dispositivo al momento de la detección.
  final double? latitude;

  /// Longitud del dispositivo al momento de la detección.
  final double? longitude;

  /// Duración estimada del evento en milisegundos.
  final int durationMs;

  /// Número total de muestras procesadas durante el evento.
  final int sampleCount;

  /// Indica si el evento es un sismo real confirmado.
  bool get isConfirmedEarthquake =>
      eventType == SeismicEventType.earthquake &&
      analysisState == SeismicAnalysisState.classified;

  /// Indica si el evento requiere alerta al usuario.
  bool get requiresAlert =>
      eventType == SeismicEventType.earthquake ||
      eventType == SeismicEventType.possibleEarthquake;

  /// Crea una copia del evento con campos modificados.
  SeismicEvent copyWith({
    String? id,
    DateTime? timestamp,
    double? staLtaRatio,
    double? triggerThreshold,
    SeismicEventType? eventType,
    SeismicAnalysisState? analysisState,
    double? cnnConfidence,
    double? peakAcceleration,
    double? latitude,
    double? longitude,
    int? durationMs,
    int? sampleCount,
  }) {
    return SeismicEvent(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      staLtaRatio: staLtaRatio ?? this.staLtaRatio,
      triggerThreshold: triggerThreshold ?? this.triggerThreshold,
      eventType: eventType ?? this.eventType,
      analysisState: analysisState ?? this.analysisState,
      cnnConfidence: cnnConfidence ?? this.cnnConfidence,
      peakAcceleration: peakAcceleration ?? this.peakAcceleration,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      durationMs: durationMs ?? this.durationMs,
      sampleCount: sampleCount ?? this.sampleCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        timestamp,
        staLtaRatio,
        triggerThreshold,
        eventType,
        analysisState,
        cnnConfidence,
        peakAcceleration,
        latitude,
        longitude,
        durationMs,
        sampleCount,
      ];

  @override
  String toString() =>
      'SeismicEvent(id: $id, type: $eventType, ratio: ${staLtaRatio.toStringAsFixed(2)}, '
      'confidence: ${(cnnConfidence * 100).toStringAsFixed(1)}%)';
}
