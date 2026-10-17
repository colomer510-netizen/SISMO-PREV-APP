// ============================================================================
// SismoGuard — Analizador de Modo Simulacro (Drill Mode Analyzer)
// ============================================================================
// Analiza el campo <status> de un mensaje CAP para determinar si la alerta
// es real o un ejercicio/simulacro, y configura la respuesta de la UI.
//
// Reglas:
// - <status>Actual</status>  → Alarmas máximas, protocolo de emergencia
// - <status>Exercise</status> → Modo seguro: borde naranja + "SIMULACRO EN CURSO"
// - <status>Test</status>    → Solo logging interno
// - <status>System</status>  → Solo logging interno
// - <status>Draft</status>   → Ignorar completamente
// ============================================================================

import 'package:flutter/material.dart';

import '../../../../core/constants/cap_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/cap_alert.dart';

/// Resultado del análisis de modo simulacro.
///
/// Contiene toda la información que la UI necesita para presentar
/// una alerta de forma apropiada según su estado (real vs simulacro).
class DrillModeResult {
  const DrillModeResult({
    required this.isRealAlert,
    required this.isDrill,
    required this.isTest,
    required this.shouldAlarm,
    required this.shouldShowUI,
    required this.uiBorderColor,
    required this.uiBorderWidth,
    required this.bannerText,
    required this.bannerColor,
    required this.logLevel,
    required this.statusLabel,
  });

  /// Es una alerta REAL que requiere acción.
  final bool isRealAlert;

  /// Es un simulacro/ejercicio.
  final bool isDrill;

  /// Es una prueba técnica (sin mostrar al usuario).
  final bool isTest;

  /// Si se deben activar las alarmas (sonido/vibración).
  final bool shouldAlarm;

  /// Si se debe mostrar la alerta en la UI.
  final bool shouldShowUI;

  /// Color del borde de la UI (naranja para simulacro, rojo para real).
  final Color uiBorderColor;

  /// Grosor del borde de la UI.
  final double uiBorderWidth;

  /// Texto del banner superpuesto ("SIMULACRO EN CURSO", etc.).
  final String bannerText;

  /// Color de fondo del banner.
  final Color bannerColor;

  /// Nivel de logging: 'critical', 'warning', 'info', 'debug'.
  final String logLevel;

  /// Etiqueta descriptiva del estado.
  final String statusLabel;
}

/// Analiza el estado de una alerta CAP y determina el modo de operación.
///
/// Este es un componente crítico de seguridad: NUNCA debe suprimir
/// una alerta real. En caso de duda, trata el mensaje como real.
class DrillModeAnalyzer {
  /// Analiza una alerta CAP y retorna la configuración de UI.
  ///
  /// Principio: **Fail-safe hacia alerta real.**
  /// Si hay cualquier ambigüedad, el sistema asume que es real.
  DrillModeResult analyze(CapAlert alert) {
    switch (alert.status) {
      // ── ACTUAL: Alerta REAL ──
      case CapStatus.actual:
        return const DrillModeResult(
          isRealAlert: true,
          isDrill: false,
          isTest: false,
          shouldAlarm: true,
          shouldShowUI: true,
          uiBorderColor: AppColors.severityExtreme,
          uiBorderWidth: 4.0,
          bannerText: '',
          bannerColor: Colors.transparent,
          logLevel: 'critical',
          statusLabel: 'ALERTA REAL',
        );

      // ── EXERCISE: Simulacro ──
      case CapStatus.exercise:
        return const DrillModeResult(
          isRealAlert: false,
          isDrill: true,
          isTest: false,
          shouldAlarm: false, // No activar alarmas reales
          shouldShowUI: true,  // Mostrar la UI para educar
          uiBorderColor: AppColors.drillModeBorder,
          uiBorderWidth: 6.0, // Borde más grueso para hacer obvio
          bannerText: '🔶 SIMULACRO EN CURSO 🔶',
          bannerColor: AppColors.drillModeBackground,
          logLevel: 'warning',
          statusLabel: 'SIMULACRO',
        );

      // ── TEST: Prueba técnica ──
      case CapStatus.test:
        return const DrillModeResult(
          isRealAlert: false,
          isDrill: false,
          isTest: true,
          shouldAlarm: false,
          shouldShowUI: false, // No mostrar al usuario
          uiBorderColor: AppColors.severityUnknown,
          uiBorderWidth: 2.0,
          bannerText: 'PRUEBA TÉCNICA',
          bannerColor: AppColors.darkSurfaceElevated,
          logLevel: 'info',
          statusLabel: 'PRUEBA',
        );

      // ── SYSTEM: Mensaje de sistema ──
      case CapStatus.system:
        return const DrillModeResult(
          isRealAlert: false,
          isDrill: false,
          isTest: true,
          shouldAlarm: false,
          shouldShowUI: false,
          uiBorderColor: AppColors.severityUnknown,
          uiBorderWidth: 1.0,
          bannerText: 'MENSAJE DE SISTEMA',
          bannerColor: AppColors.darkSurfaceElevated,
          logLevel: 'debug',
          statusLabel: 'SISTEMA',
        );

      // ── DRAFT: Borrador (ignorar) ──
      case CapStatus.draft:
        return const DrillModeResult(
          isRealAlert: false,
          isDrill: false,
          isTest: false,
          shouldAlarm: false,
          shouldShowUI: false,
          uiBorderColor: Colors.transparent,
          uiBorderWidth: 0.0,
          bannerText: '',
          bannerColor: Colors.transparent,
          logLevel: 'debug',
          statusLabel: 'BORRADOR',
        );
    }
  }

  /// Analiza directamente un string de status XML.
  ///
  /// Útil cuando solo se tiene el valor del campo <status>
  /// sin haber parseado el mensaje CAP completo.
  DrillModeResult analyzeFromStatusString(String statusXml) {
    final status = CapStatus.fromXml(statusXml);

    // Crear un CapAlert mínimo para reutilizar la lógica principal
    final minimalAlert = CapAlert(
      identifier: 'analysis',
      sender: 'analyzer',
      sentDate: DateTime.now(),
      status: status,
      msgType: CapMsgType.alert,
      scope: CapScope.public,
    );

    return analyze(minimalAlert);
  }

  /// Determina si un mensaje debe interrumpir al usuario.
  ///
  /// Solo los mensajes con status "Actual" deben interrumpir
  /// la actividad del usuario (por ejemplo, forzar la apertura de la app).
  bool shouldInterruptUser(CapAlert alert) {
    return alert.isActualAlert && alert.maxPriorityScore >= 8;
  }
}
