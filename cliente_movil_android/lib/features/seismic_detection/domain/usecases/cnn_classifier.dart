// ============================================================================
// SismoGuard — Clasificador CNN (Red Neuronal Convolucional)
// ============================================================================
// Clasifica ventanas de datos del acelerómetro para distinguir entre
// actividad sísmica real y movimientos humanos (falsos positivos).
//
// Pipeline: Trigger STA/LTA → Extraer ventana 2s → Normalizar → CNN → Resultado
//
// Modelo TFLite esperado:
// - Input:  [1, 100, 3] → 2 segundos × 50Hz × 3 ejes (x, y, z)
// - Output: [1, 2] → [prob_earthquake, prob_human_activity]
// ============================================================================

import 'dart:typed_data';

import '../../core/constants/app_constants.dart';

/// Resultado de la clasificación CNN.
class CnnClassificationResult {
  const CnnClassificationResult({
    required this.isEarthquake,
    required this.confidence,
    required this.earthquakeProbability,
    required this.humanActivityProbability,
    required this.inferenceTimeMs,
  });

  /// Indica si el modelo clasificó el evento como sismo.
  final bool isEarthquake;

  /// Confianza de la clasificación (0.0 - 1.0).
  final double confidence;

  /// Probabilidad de que sea un terremoto.
  final double earthquakeProbability;

  /// Probabilidad de que sea actividad humana.
  final double humanActivityProbability;

  /// Tiempo de inferencia en milisegundos.
  final int inferenceTimeMs;

  @override
  String toString() =>
      'CnnResult(earthquake: ${isEarthquake ? "SÍ" : "NO"}, '
      'confidence: ${(confidence * 100).toStringAsFixed(1)}%, '
      'inference: ${inferenceTimeMs}ms)';
}

/// Clasificador CNN local para filtrado de falsos positivos sísmicos.
///
/// Flujo de uso:
/// 1. El algoritmo STA/LTA detecta un trigger.
/// 2. Se extrae una ventana de 2 segundos de datos del acelerómetro.
/// 3. Se normaliza y alimenta al modelo TFLite.
/// 4. El modelo retorna la clasificación: sismo vs. actividad humana.
///
/// Nota: En esta versión base, el clasificador opera en modo STUB
/// hasta que se provea un modelo .tflite entrenado. Retorna "uncertain"
/// por defecto para no suprimir alertas reales.
class CnnClassifier {
  CnnClassifier({
    String? modelPath,
    double? confidenceThreshold,
    int? inputSampleCount,
  })  : _modelPath = modelPath ?? AppConstants.cnnModelAsset,
        _confidenceThreshold =
            confidenceThreshold ?? AppConstants.cnnConfidenceThreshold,
        _inputSampleCount = inputSampleCount ??
            (AppConstants.cnnWindowSeconds * AppConstants.accelerometerSampleRateHz)
                .round();

  final String _modelPath;
  final double _confidenceThreshold;
  final int _inputSampleCount; // 100 muestras (2s × 50Hz)

  // ─── Estado del Modelo ───
  bool _isModelLoaded = false;
  // Interpreter? _interpreter; // Descomentar con tflite_flutter

  /// Indica si el modelo TFLite está cargado y listo.
  bool get isModelLoaded => _isModelLoaded;

  /// Carga el modelo TFLite desde los assets.
  ///
  /// Debe llamarse una vez durante la inicialización de la app.
  /// Retorna true si el modelo se cargó correctamente.
  Future<bool> loadModel() async {
    try {
      // ── Implementación con tflite_flutter ──
      // Descomentar cuando el modelo .tflite esté disponible:
      //
      // _interpreter = await Interpreter.fromAsset(_modelPath);
      //
      // // Configurar opciones de inferencia
      // final options = InterpreterOptions()
      //   ..threads = 2  // Usar 2 hilos para mejor rendimiento
      //   ..addDelegate(NnApiDelegate()); // Aceleración hardware si disponible
      //
      // _interpreter = await Interpreter.fromAsset(
      //   _modelPath,
      //   options: options,
      // );
      //
      // _isModelLoaded = true;

      // Stub: simular carga exitosa
      _isModelLoaded = false; // false hasta tener modelo real
      return _isModelLoaded;
    } catch (e) {
      _isModelLoaded = false;
      return false;
    }
  }

  /// Clasifica una ventana de datos del acelerómetro.
  ///
  /// [samples] debe contener [_inputSampleCount] muestras,
  /// cada una como [x, y, z] en m/s².
  ///
  /// Retorna un [CnnClassificationResult] con la clasificación.
  Future<CnnClassificationResult> classify(
    List<List<double>> samples,
  ) async {
    final stopwatch = Stopwatch()..start();

    // ── Validar entrada ──
    if (samples.length < _inputSampleCount) {
      // Datos insuficientes: no suprimir la alerta
      return CnnClassificationResult(
        isEarthquake: true, // Fail-safe: asumir que es real
        confidence: 0.0,
        earthquakeProbability: 0.5,
        humanActivityProbability: 0.5,
        inferenceTimeMs: stopwatch.elapsedMilliseconds,
      );
    }

    // ── Si el modelo no está cargado, usar fail-safe ──
    if (!_isModelLoaded) {
      stopwatch.stop();
      return CnnClassificationResult(
        isEarthquake: true, // IMPORTANTE: no suprimir alertas sin modelo
        confidence: 0.0,
        earthquakeProbability: 0.5,
        humanActivityProbability: 0.5,
        inferenceTimeMs: stopwatch.elapsedMilliseconds,
      );
    }

    // ── Preprocesar datos ──
    final input = _preprocessSamples(samples);

    // ── Ejecutar inferencia ──
    // Descomentar con tflite_flutter:
    //
    // // Preparar tensor de salida [1, 2]
    // var output = List.filled(1 * 2, 0.0).reshape([1, 2]);
    //
    // // Ejecutar inferencia
    // _interpreter!.run(input, output);
    //
    // final earthquakeProb = output[0][0];
    // final humanProb = output[0][1];

    // ── Stub: resultado placeholder ──
    const earthquakeProb = 0.5;
    const humanProb = 0.5;

    stopwatch.stop();

    // ── Determinar clasificación final ──
    final isEarthquake = earthquakeProb >= _confidenceThreshold;
    final confidence = isEarthquake ? earthquakeProb : humanProb;

    return CnnClassificationResult(
      isEarthquake: isEarthquake,
      confidence: confidence,
      earthquakeProbability: earthquakeProb,
      humanActivityProbability: humanProb,
      inferenceTimeMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// Preprocesa las muestras del acelerómetro para el tensor de entrada.
  ///
  /// Normalización:
  /// 1. Tomar las últimas [_inputSampleCount] muestras
  /// 2. Normalizar cada eje al rango [-1, 1] dividiendo por maxRange
  /// 3. Reshape a [1, samples, 3]
  Float32List _preprocessSamples(List<List<double>> samples) {
    const maxAccelRange = 39.2; // ±4g en m/s² (rango típico del acelerómetro)

    // Tomar las últimas N muestras
    final window = samples.length > _inputSampleCount
        ? samples.sublist(samples.length - _inputSampleCount)
        : samples;

    // Crear tensor de entrada [1, _inputSampleCount, 3]
    final input = Float32List(_inputSampleCount * 3);

    for (var i = 0; i < window.length; i++) {
      // Normalizar cada eje al rango [-1, 1]
      input[i * 3 + 0] = (window[i][0] / maxAccelRange).clamp(-1.0, 1.0);
      input[i * 3 + 1] = (window[i][1] / maxAccelRange).clamp(-1.0, 1.0);
      input[i * 3 + 2] = (window[i][2] / maxAccelRange).clamp(-1.0, 1.0);
    }

    return input;
  }

  /// Libera recursos del modelo.
  void dispose() {
    // _interpreter?.close();
    _isModelLoaded = false;
  }
}
