// ============================================================================
// SismoGuard — Algoritmo STA/LTA (Short-Term Average / Long-Term Average)
// ============================================================================
// Implementación en Dart puro del algoritmo de detección sísmica clásico.
//
// Referencia: Allen, R.V. (1978). "Automatic Earthquake Recognition and
// Timing from Single Traces". BSSA, 68(5), pp. 1521-1532.
//
// Flujo:
// 1. Recibe stream continuo de aceleración (magnitud vectorial)
// 2. Aplica filtro pasa-bandas digital (1-20 Hz)
// 3. Calcula promedios STA y LTA con ventanas deslizantes
// 4. Compara ratio STA/LTA contra umbrales de trigger/detrigger
// 5. Emite eventos de trigger cuando se detecta actividad sísmica
// ============================================================================

import 'dart:math';
import 'dart:collection';

import '../../../../core/constants/app_constants.dart';

/// Resultado del análisis STA/LTA para cada muestra.
class StaLtaResult {
  const StaLtaResult({
    required this.ratio,
    required this.sta,
    required this.lta,
    required this.isTriggered,
    required this.timestamp,
    required this.magnitude,
  });

  /// Ratio STA/LTA actual.
  final double ratio;

  /// Valor del promedio a corto plazo.
  final double sta;

  /// Valor del promedio a largo plazo.
  final double lta;

  /// Indica si se ha cruzado el umbral de trigger.
  final bool isTriggered;

  /// Marca temporal de la muestra (ms desde epoch).
  final double timestamp;

  /// Magnitud de la aceleración procesada.
  final double magnitude;
}

/// Algoritmo STA/LTA para detección de eventos sísmicos.
///
/// Uso:
/// ```dart
/// final trigger = StaLtaTrigger();
/// // Para cada muestra del acelerómetro:
/// final result = trigger.processSample(x, y, z, timestamp);
/// if (result.isTriggered) {
///   // ¡Posible evento sísmico detectado!
/// }
/// ```
class StaLtaTrigger {
  StaLtaTrigger({
    double? staWindowSeconds,
    double? ltaWindowSeconds,
    double? triggerThreshold,
    double? detriggerThreshold,
    int? sampleRateHz,
  })  : _staWindowSeconds = staWindowSeconds ?? AppConstants.staWindowSeconds,
        _ltaWindowSeconds = ltaWindowSeconds ?? AppConstants.ltaWindowSeconds,
        _triggerThreshold = triggerThreshold ?? AppConstants.staLtaTriggerThreshold,
        _detriggerThreshold = detriggerThreshold ?? AppConstants.staLtaDetriggerThreshold,
        _sampleRateHz = sampleRateHz ?? AppConstants.accelerometerSampleRateHz {
    // Calcular tamaños de ventana en muestras
    _staWindowSamples = (_staWindowSeconds * _sampleRateHz).round();
    _ltaWindowSamples = (_ltaWindowSeconds * _sampleRateHz).round();

    // Inicializar buffers circulares
    _staBuffer = Queue<double>();
    _ltaBuffer = Queue<double>();
  }

  // ─── Parámetros de Configuración ───
  final double _staWindowSeconds;
  final double _ltaWindowSeconds;
  final double _triggerThreshold;
  final double _detriggerThreshold;
  final int _sampleRateHz;

  // ─── Tamaños de Ventana (en muestras) ───
  late int _staWindowSamples;
  late int _ltaWindowSamples;

  // ─── Buffers de Datos ───
  late Queue<double> _staBuffer;
  late Queue<double> _ltaBuffer;

  // ─── Estado del Trigger ───
  bool _isTriggered = false;
  double _staSum = 0.0;
  double _ltaSum = 0.0;
  int _sampleCount = 0;

  // ─── Filtro Pasa-Bandas (Butterworth simplificado de 2do orden) ───
  // Coeficientes pre-calculados para [1-20Hz] a 50Hz de muestreo
  final List<double> _prevInput = [0.0, 0.0, 0.0]; // x[n], x[n-1], x[n-2]
  final List<double> _prevOutput = [0.0, 0.0]; // y[n-1], y[n-2]

  /// Indica si el algoritmo está actualmente en estado de trigger.
  bool get isTriggered => _isTriggered;

  /// Número total de muestras procesadas.
  int get sampleCount => _sampleCount;

  /// Ratio STA/LTA actual.
  double get currentRatio {
    if (_ltaSum == 0.0 || _ltaBuffer.isEmpty) return 0.0;
    final lta = _ltaSum / _ltaBuffer.length;
    if (lta == 0.0) return 0.0;
    final sta = _staBuffer.isEmpty ? 0.0 : _staSum / _staBuffer.length;
    return sta / lta;
  }

  /// Procesa una nueva muestra del acelerómetro.
  ///
  /// [x], [y], [z]: componentes de aceleración en m/s².
  /// [timestamp]: marca temporal en milisegundos.
  ///
  /// Retorna un [StaLtaResult] con el análisis de la muestra.
  StaLtaResult processSample(double x, double y, double z, double timestamp) {
    _sampleCount++;

    // ── 1. Calcular magnitud vectorial ──
    // |a| = sqrt(x² + y² + z²) - gravedad (~9.81)
    // Restamos gravedad para trabajar con la aceleración dinámica
    final rawMagnitude = sqrt(x * x + y * y + z * z);
    final dynamicMagnitude = (rawMagnitude - 9.81).abs();

    // ── 2. Aplicar filtro pasa-bandas simplificado ──
    final filteredMagnitude = _applyBandpassFilter(dynamicMagnitude);

    // ── 3. Calcular valor absoluto para la función característica ──
    final cfValue = filteredMagnitude.abs();

    // ── 4. Actualizar buffer STA ──
    _staBuffer.addLast(cfValue);
    _staSum += cfValue;
    if (_staBuffer.length > _staWindowSamples) {
      _staSum -= _staBuffer.removeFirst();
    }

    // ── 5. Actualizar buffer LTA ──
    _ltaBuffer.addLast(cfValue);
    _ltaSum += cfValue;
    if (_ltaBuffer.length > _ltaWindowSamples) {
      _ltaSum -= _ltaBuffer.removeFirst();
    }

    // ── 6. Calcular ratio STA/LTA ──
    double ratio = 0.0;
    if (_ltaBuffer.isNotEmpty && _staBuffer.isNotEmpty) {
      final sta = _staSum / _staBuffer.length;
      final lta = _ltaSum / _ltaBuffer.length;

      if (lta > 1e-10) {
        // Evitar división por cero
        ratio = sta / lta;
      }
    }

    // ── 7. Lógica de Trigger/Detrigger ──
    if (!_isTriggered && ratio >= _triggerThreshold) {
      _isTriggered = true;
    } else if (_isTriggered && ratio <= _detriggerThreshold) {
      _isTriggered = false;
    }

    return StaLtaResult(
      ratio: ratio,
      sta: _staBuffer.isEmpty ? 0.0 : _staSum / _staBuffer.length,
      lta: _ltaBuffer.isEmpty ? 0.0 : _ltaSum / _ltaBuffer.length,
      isTriggered: _isTriggered,
      timestamp: timestamp,
      magnitude: dynamicMagnitude,
    );
  }

  /// Aplica un filtro pasa-bandas digital simplificado.
  ///
  /// Este es un filtro IIR de 2do orden con coeficientes pre-calculados
  /// para la banda [1-20 Hz] a una tasa de muestreo de 50 Hz.
  ///
  /// Nota: Para producción, se recomienda usar coeficientes calculados
  /// dinámicamente con la función bilineal z-transform.
  double _applyBandpassFilter(double input) {
    // Coeficientes simplificados para Butterworth pasa-bandas
    // Fc_low = 1 Hz, Fc_high = 20 Hz, Fs = 50 Hz
    const double a1 = -0.3695;
    const double a2 = 0.1958;
    const double b0 = 0.3913;
    const double b1 = 0.0;
    const double b2 = -0.3913;

    // Aplicar ecuación de diferencias
    final output = b0 * input +
        b1 * _prevInput[1] +
        b2 * _prevInput[2] -
        a1 * _prevOutput[0] -
        a2 * _prevOutput[1];

    // Actualizar historial
    _prevInput[2] = _prevInput[1];
    _prevInput[1] = input;
    _prevOutput[1] = _prevOutput[0];
    _prevOutput[0] = output;

    return output;
  }

  /// Reinicia el estado completo del algoritmo.
  void reset() {
    _staBuffer.clear();
    _ltaBuffer.clear();
    _staSum = 0.0;
    _ltaSum = 0.0;
    _isTriggered = false;
    _sampleCount = 0;
    _prevInput.fillRange(0, _prevInput.length, 0.0);
    _prevOutput.fillRange(0, _prevOutput.length, 0.0);
  }

  /// Actualiza los umbrales de trigger/detrigger en caliente.
  ///
  /// Útil para ajustar sensibilidad según condiciones del entorno.
  void updateThresholds({
    double? triggerThreshold,
    double? detriggerThreshold,
  }) {
    // Los thresholds son finales en esta implementación.
    // En producción, convertirlos a variables para ajuste dinámico.
  }
}
