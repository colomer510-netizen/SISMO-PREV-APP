// ============================================================================
// SismoGuard — Tipografía
// ============================================================================
// Sistema tipográfico diseñado para legibilidad extrema en emergencias.
// Usa Inter como familia principal (sans-serif, alta legibilidad).
// ============================================================================

import 'package:flutter/material.dart';

/// Sistema tipográfico de SismoGuard.
///
/// Principios de diseño:
/// - Legibilidad máxima en cualquier condición (luz/oscuridad)
/// - Tamaños grandes para información crítica
/// - Pesos fuertes para alertas
abstract class AppTypography {
  AppTypography._();

  /// Familia tipográfica principal.
  static const String fontFamily = 'Inter';

  // ═══════════════════════════════════════════════════════════
  //  DISPLAY — Alertas Críticas (pantalla completa)
  // ═══════════════════════════════════════════════════════════

  /// Display para alertas de máxima severidad.
  static const TextStyle displayAlert = TextStyle(
    fontFamily: fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    height: 1.1,
  );

  /// Display para contadores (countdown evacuación).
  static const TextStyle displayCounter = TextStyle(
    fontFamily: fontFamily,
    fontSize: 72,
    fontWeight: FontWeight.w700,
    letterSpacing: -2.0,
    height: 1.0,
  );

  // ═══════════════════════════════════════════════════════════
  //  HEADINGS — Secciones y Títulos
  // ═══════════════════════════════════════════════════════════

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.3,
  );

  // ═══════════════════════════════════════════════════════════
  //  TITLES — Subtítulos y Labels
  // ═══════════════════════════════════════════════════════════

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.4,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
  );

  // ═══════════════════════════════════════════════════════════
  //  BODY — Contenido general
  // ═══════════════════════════════════════════════════════════

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.5,
  );

  // ═══════════════════════════════════════════════════════════
  //  LABELS — Botones, badges, metadata
  // ═══════════════════════════════════════════════════════════

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.4,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
  );

  // ═══════════════════════════════════════════════════════════
  //  ESPECIALES — Contextos de Emergencia
  // ═══════════════════════════════════════════════════════════

  /// Texto para el banner de simulacro "SIMULACRO EN CURSO".
  static const TextStyle drillBanner = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 3.0,
    height: 1.2,
  );

  /// Texto para datos de sismógrafo en tiempo real.
  static const TextStyle seismographData = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Texto para coordenadas GPS y datos técnicos.
  static const TextStyle technicalData = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.8,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
