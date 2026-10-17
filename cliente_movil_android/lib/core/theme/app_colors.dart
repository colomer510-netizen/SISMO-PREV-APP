// ============================================================================
// SismoGuard — Paleta de Colores
// ============================================================================
// Sistema de colores diseñado para máxima visibilidad en condiciones
// de emergencia: alto contraste, colores de alerta universales,
// legibilidad en luz solar directa y oscuridad total.
// ============================================================================

import 'package:flutter/material.dart';

/// Paleta de colores de SismoGuard.
///
/// Organizada en categorías funcionales para emergencias:
/// - Colores primarios de la marca
/// - Colores de severidad (alineados con CAP 1.2)
/// - Colores de estado del sistema
/// - Colores de superficie y texto
abstract class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════════════
  //  MARCA PRINCIPAL
  // ═══════════════════════════════════════════════════════════

  /// Azul profundo: seguridad, confianza, tecnología.
  static const Color primary = Color(0xFF0A2463);

  /// Variante clara del primario.
  static const Color primaryLight = Color(0xFF1E3A7A);

  /// Variante oscura del primario.
  static const Color primaryDark = Color(0xFF061539);

  /// Acento cian eléctrico: acciones, interactividad.
  static const Color accent = Color(0xFF00E5FF);

  /// Acento secundario: teal para estados positivos.
  static const Color accentSecondary = Color(0xFF00BFA5);

  // ═══════════════════════════════════════════════════════════
  //  SEVERIDAD CAP — COLORES DE ALERTA
  // ═══════════════════════════════════════════════════════════

  /// EXTREME: Rojo crítico pulsante — amenaza máxima a la vida.
  static const Color severityExtreme = Color(0xFFD50000);
  static const Color severityExtremeGlow = Color(0xFFFF1744);

  /// SEVERE: Naranja intenso — amenaza significativa.
  static const Color severitySevere = Color(0xFFFF6D00);
  static const Color severitySevereGlow = Color(0xFFFF9100);

  /// MODERATE: Amarillo — posible amenaza.
  static const Color severityModerate = Color(0xFFFFD600);
  static const Color severityModerateGlow = Color(0xFFFFEA00);

  /// MINOR: Verde — impacto mínimo.
  static const Color severityMinor = Color(0xFF00C853);
  static const Color severityMinorGlow = Color(0xFF69F0AE);

  /// UNKNOWN: Gris — sin datos.
  static const Color severityUnknown = Color(0xFF78909C);

  // ═══════════════════════════════════════════════════════════
  //  ESTADOS DEL SISTEMA
  // ═══════════════════════════════════════════════════════════

  /// Sistema activo y funcionando correctamente.
  static const Color statusActive = Color(0xFF00E676);

  /// Sistema en advertencia / degradado.
  static const Color statusWarning = Color(0xFFFFAB00);

  /// Sistema en error / crítico.
  static const Color statusError = Color(0xFFFF1744);

  /// Sistema inactivo / offline.
  static const Color statusInactive = Color(0xFF546E7A);

  /// Modo simulacro activo.
  static const Color drillModeBorder = Color(0xFFFF6F00);
  static const Color drillModeBackground = Color(0x33FF6F00);

  // ═══════════════════════════════════════════════════════════
  //  COMUNICACIONES
  // ═══════════════════════════════════════════════════════════

  /// Bluetooth / BLE Mesh activo.
  static const Color commBluetooth = Color(0xFF2979FF);

  /// LoRa / Meshtastic activo.
  static const Color commLoRa = Color(0xFF7C4DFF);

  /// SMS Fallback activo.
  static const Color commSms = Color(0xFF00BFA5);

  /// Conexión Internet activa.
  static const Color commInternet = Color(0xFF00E5FF);

  /// Satelital NTN.
  static const Color commSatellite = Color(0xFFEA80FC);

  // ═══════════════════════════════════════════════════════════
  //  SUPERFICIES — MODO OSCURO
  // ═══════════════════════════════════════════════════════════

  /// Fondo principal modo oscuro.
  static const Color darkBackground = Color(0xFF0D1117);

  /// Superficie elevada (cards) modo oscuro.
  static const Color darkSurface = Color(0xFF161B22);

  /// Superficie elevada nivel 2.
  static const Color darkSurfaceElevated = Color(0xFF1C2333);

  /// Borde sutil modo oscuro.
  static const Color darkBorder = Color(0xFF30363D);

  /// Texto primario modo oscuro.
  static const Color darkTextPrimary = Color(0xFFF0F6FC);

  /// Texto secundario modo oscuro.
  static const Color darkTextSecondary = Color(0xFF8B949E);

  /// Texto terciario / hints.
  static const Color darkTextTertiary = Color(0xFF6E7681);

  // ═══════════════════════════════════════════════════════════
  //  SUPERFICIES — MODO CLARO
  // ═══════════════════════════════════════════════════════════

  /// Fondo principal modo claro.
  static const Color lightBackground = Color(0xFFF6F8FA);

  /// Superficie elevada modo claro.
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// Borde modo claro.
  static const Color lightBorder = Color(0xFFD0D7DE);

  /// Texto primario modo claro.
  static const Color lightTextPrimary = Color(0xFF1F2328);

  /// Texto secundario modo claro.
  static const Color lightTextSecondary = Color(0xFF656D76);

  // ═══════════════════════════════════════════════════════════
  //  GRADIENTES
  // ═══════════════════════════════════════════════════════════

  /// Gradiente de alerta extrema (fondo pulsante).
  static const LinearGradient extremeAlertGradient = LinearGradient(
    colors: [Color(0xFFD50000), Color(0xFFFF1744)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradiente del dashboard en estado normal.
  static const LinearGradient dashboardGradient = LinearGradient(
    colors: [Color(0xFF0A2463), Color(0xFF1E3A7A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Gradiente de la barra de estado del sistema.
  static const LinearGradient systemStatusGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF00BFA5)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ═══════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════

  /// Retorna el color correspondiente a un nivel de severidad CAP.
  static Color fromSeverityLevel(int level) {
    switch (level) {
      case 4:
        return severityExtreme;
      case 3:
        return severitySevere;
      case 2:
        return severityModerate;
      case 1:
        return severityMinor;
      default:
        return severityUnknown;
    }
  }

  /// Retorna el color glow correspondiente a un nivel de severidad.
  static Color glowFromSeverityLevel(int level) {
    switch (level) {
      case 4:
        return severityExtremeGlow;
      case 3:
        return severitySevereGlow;
      case 2:
        return severityModerateGlow;
      case 1:
        return severityMinorGlow;
      default:
        return severityUnknown;
    }
  }
}
