// ============================================================================
// SismoGuard — Punto de Entrada Principal
// ============================================================================
// Aplicación de misión crítica para Alerta Temprana de Desastres Naturales.
// Inicializa todos los servicios críticos antes de renderizar la UI.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'injection_container.dart' as di;
import 'core/platform/foreground_service_controller.dart';

/// Punto de entrada de la aplicación.
/// 
/// Secuencia de inicialización crítica:
/// 1. Binding de Flutter Widgets
/// 2. Orientación bloqueada (portrait) para emergencias
/// 3. Base de datos Hive local
/// 4. Inyección de dependencias
/// 5. Foreground Service para detección sísmica continua
/// 6. Renderizado de la UI
void main() async {
  // ── 1. Asegurar que el binding de widgets esté inicializado ──
  WidgetsFlutterBinding.ensureInitialized();

  // ── 2. Bloquear orientación en portrait para contextos de emergencia ──
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── 3. Inicializar almacenamiento local Hive ──
  await Hive.initFlutter();

  // ── 4. Registrar todas las dependencias (GetIt) ──
  await di.init();

  // ── 5. Iniciar el Foreground Service de detección sísmica ──
  await ForegroundServiceController.instance.initialize();

  // ── 6. Lanzar la aplicación ──
  runApp(const SismoGuardApp());
}
