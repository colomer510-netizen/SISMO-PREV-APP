// ============================================================================
// SismoGuard — Matriz de Comportamiento de Alertas
// ============================================================================
// Define cómo el teléfono debe reaccionar ante cada combinación de
// <urgency>, <severity> y <certainty> del protocolo CAP 1.2.
//
// Controla: volumen, patrón de vibración, encendido de pantalla,
// tipo de sonido de alarma, y duración de la notificación.
// ============================================================================

import '../../../../core/constants/cap_constants.dart';

/// Perfil de comportamiento del dispositivo ante una alerta.
///
/// Define exactamente cómo el teléfono debe reaccionar:
/// volumen, vibración, pantalla, sonido de alarma.
class BehaviorProfile {
  const BehaviorProfile({
    required this.volumePercent,
    required this.vibrationPattern,
    required this.wakeScreen,
    required this.soundAsset,
    required this.repeatAlarm,
    required this.overrideSilentMode,
    required this.flashlightStrobe,
    required this.priority,
    required this.label,
  });

  /// Porcentaje de volumen (0-100). 100 = máximo del dispositivo.
  final int volumePercent;

  /// Patrón de vibración [pausa, vibrar, pausa, vibrar, ...] en milisegundos.
  final List<int> vibrationPattern;

  /// Si debe encender la pantalla al recibir la alerta.
  final bool wakeScreen;

  /// Asset del sonido de alarma a reproducir.
  final String soundAsset;

  /// Si la alarma debe repetirse continuamente.
  final bool repeatAlarm;

  /// Si debe ignorar el modo silencioso/vibración del dispositivo.
  final bool overrideSilentMode;

  /// Si debe activar el estrobo del flash LED.
  final bool flashlightStrobe;

  /// Nivel de prioridad numérica (mayor = más urgente).
  final int priority;

  /// Etiqueta descriptiva del perfil.
  final String label;
}

/// Matriz de comportamiento que mapea parámetros CAP a perfiles
/// de respuesta del dispositivo.
///
/// La matriz evalúa la combinación de:
/// - [CapUrgency]: marco temporal para la acción
/// - [CapSeverity]: nivel de amenaza
/// - [CapCertainty]: probabilidad del evento
///
/// Y produce un [BehaviorProfile] que define la reacción del teléfono.
class AlertBehaviorMatrix {
  // ═══════════════════════════════════════════════════════════
  //  PERFILES PREDEFINIDOS
  // ═══════════════════════════════════════════════════════════

  /// NIVEL MÁXIMO: Sirena de emergencia continua.
  /// Trigger: Immediate + Extreme + Observed/Likely
  static const BehaviorProfile _maxAlert = BehaviorProfile(
    volumePercent: 100,
    vibrationPattern: [0, 1000, 200, 1000, 200, 1000, 200, 1000],
    wakeScreen: true,
    soundAsset: 'assets/sounds/siren_extreme.mp3',
    repeatAlarm: true,
    overrideSilentMode: true,
    flashlightStrobe: true,
    priority: 10,
    label: '🔴 ALERTA MÁXIMA',
  );

  /// NIVEL ALTO: Alarma fuerte con vibración intensa.
  /// Trigger: Immediate/Expected + Severe + Observed/Likely
  static const BehaviorProfile _highAlert = BehaviorProfile(
    volumePercent: 90,
    vibrationPattern: [0, 800, 300, 800, 300, 800],
    wakeScreen: true,
    soundAsset: 'assets/sounds/alarm_severe.mp3',
    repeatAlarm: true,
    overrideSilentMode: true,
    flashlightStrobe: false,
    priority: 8,
    label: '🟠 ALERTA ALTA',
  );

  /// NIVEL MEDIO: Alarma moderada con vibración.
  /// Trigger: Expected + Moderate + Likely/Possible
  static const BehaviorProfile _mediumAlert = BehaviorProfile(
    volumePercent: 70,
    vibrationPattern: [0, 500, 500, 500],
    wakeScreen: true,
    soundAsset: 'assets/sounds/alert_moderate.mp3',
    repeatAlarm: false,
    overrideSilentMode: false,
    flashlightStrobe: false,
    priority: 5,
    label: '🟡 ALERTA MEDIA',
  );

  /// NIVEL BAJO: Notificación con sonido suave.
  /// Trigger: Future + Minor/Moderate + Possible/Unlikely
  static const BehaviorProfile _lowAlert = BehaviorProfile(
    volumePercent: 40,
    vibrationPattern: [0, 300, 500],
    wakeScreen: false,
    soundAsset: 'assets/sounds/notification_info.mp3',
    repeatAlarm: false,
    overrideSilentMode: false,
    flashlightStrobe: false,
    priority: 3,
    label: '🟢 AVISO',
  );

  /// NIVEL INFORMATIVO: Solo notificación silenciosa.
  /// Trigger: Past/Unknown + cualquier combinación menor
  static const BehaviorProfile _infoOnly = BehaviorProfile(
    volumePercent: 0,
    vibrationPattern: [0, 200],
    wakeScreen: false,
    soundAsset: '',
    repeatAlarm: false,
    overrideSilentMode: false,
    flashlightStrobe: false,
    priority: 1,
    label: 'ℹ️ INFORMATIVO',
  );

  /// MODO SIMULACRO: Alarma reducida con indicadores visuales.
  static const BehaviorProfile _drillMode = BehaviorProfile(
    volumePercent: 30,
    vibrationPattern: [0, 200, 400, 200],
    wakeScreen: true,
    soundAsset: 'assets/sounds/drill_notification.mp3',
    repeatAlarm: false,
    overrideSilentMode: false,
    flashlightStrobe: false,
    priority: 2,
    label: '🟧 SIMULACRO',
  );

  // ═══════════════════════════════════════════════════════════
  //  EVALUACIÓN DE LA MATRIZ
  // ═══════════════════════════════════════════════════════════

  /// Evalúa la combinación de parámetros CAP y retorna el perfil
  /// de comportamiento correspondiente.
  ///
  /// La lógica prioriza la seguridad: en caso de duda, escala
  /// hacia un perfil más agresivo (fail-safe).
  BehaviorProfile evaluate({
    required CapUrgency urgency,
    required CapSeverity severity,
    required CapCertainty certainty,
    bool isDrill = false,
  }) {
    // Si es simulacro, usar perfil especial independientemente de los parámetros
    if (isDrill) return _drillMode;

    // Calcular score compuesto (0-12)
    final score =
        urgency.numericLevel + severity.numericLevel + certainty.numericLevel;

    // ── Reglas de decisión basadas en score compuesto ──

    // Score 10-12: ALERTA MÁXIMA
    // Immediate+Extreme+Observed, Immediate+Extreme+Likely, etc.
    if (score >= 10) return _maxAlert;

    // Score 8-9: ALERTA ALTA
    if (score >= 8) return _highAlert;

    // Score 5-7: ALERTA MEDIA
    if (score >= 5) return _mediumAlert;

    // Score 3-4: AVISO BAJO
    if (score >= 3) return _lowAlert;

    // Score 0-2: SOLO INFORMATIVO
    return _infoOnly;
  }

  /// Versión que acepta directamente valores numéricos de severidad.
  BehaviorProfile evaluateFromLevels({
    required int urgencyLevel,
    required int severityLevel,
    required int certaintyLevel,
    bool isDrill = false,
  }) {
    return evaluate(
      urgency: CapUrgency.values.firstWhere(
        (u) => u.numericLevel == urgencyLevel,
        orElse: () => CapUrgency.unknown,
      ),
      severity: CapSeverity.values.firstWhere(
        (s) => s.numericLevel == severityLevel,
        orElse: () => CapSeverity.unknown,
      ),
      certainty: CapCertainty.values.firstWhere(
        (c) => c.numericLevel == certaintyLevel,
        orElse: () => CapCertainty.unknown,
      ),
      isDrill: isDrill,
    );
  }

  /// Retorna todos los perfiles disponibles para referencia/configuración.
  static List<BehaviorProfile> get allProfiles => [
        _maxAlert,
        _highAlert,
        _mediumAlert,
        _lowAlert,
        _infoOnly,
        _drillMode,
      ];
}
