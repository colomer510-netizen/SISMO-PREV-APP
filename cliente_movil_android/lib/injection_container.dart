// ============================================================================
// SismoGuard — Contenedor de Inyección de Dependencias
// ============================================================================
// Utiliza GetIt como Service Locator para registrar todas las dependencias.
// ============================================================================

import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'core/platform/foreground_service_controller.dart';
import 'core/platform/native_bridge.dart';

/// Instancia global del Service Locator.
final sl = GetIt.instance;

/// Inicializa y registra todas las dependencias de la aplicación.
///
/// Orden de registro:
/// 1. Servicios externos (plataforma, sensores)
/// 2. Data Sources
/// 3. Repositorios
/// 4. Casos de uso
/// 5. BLoCs
Future<void> init() async {
  // ═══════════════════════════════════════════════════════════
  //  CORE — Servicios de Plataforma
  // ═══════════════════════════════════════════════════════════

  // Puente nativo para Method/Event Channels
  sl.registerLazySingleton<NativeBridge>(
    () => NativeBridge(),
  );

  // Controlador del Foreground Service
  sl.registerLazySingleton<ForegroundServiceController>(
    () => ForegroundServiceController.instance,
  );

  // Detector de conectividad
  sl.registerLazySingleton<Connectivity>(
    () => Connectivity(),
  );

  // ═══════════════════════════════════════════════════════════
  //  FEATURE: Detección Sísmica
  // ═══════════════════════════════════════════════════════════

  // Data Sources
  // sl.registerLazySingleton<AccelerometerDatasource>(
  //   () => AccelerometerDatasourceImpl(nativeBridge: sl()),
  // );

  // Repositorios
  // sl.registerLazySingleton<SeismicRepository>(
  //   () => SeismicRepositoryImpl(datasource: sl()),
  // );

  // Casos de Uso
  // sl.registerLazySingleton(() => StaLtaTrigger());
  // sl.registerLazySingleton(() => CnnClassifier());
  // sl.registerLazySingleton(() => StartSeismicMonitoring(repository: sl()));

  // BLoC
  // sl.registerFactory(() => SeismicBloc(
  //   startMonitoring: sl(),
  //   staLtaTrigger: sl(),
  //   cnnClassifier: sl(),
  // ));

  // ═══════════════════════════════════════════════════════════
  //  FEATURE: Alertas CAP
  // ═══════════════════════════════════════════════════════════

  // sl.registerLazySingleton<CapMessageDatasource>(
  //   () => CapMessageDatasourceImpl(),
  // );
  // sl.registerLazySingleton(() => AlertBehaviorMatrix());
  // sl.registerLazySingleton(() => DrillModeAnalyzer());
  // sl.registerFactory(() => AlertBloc(
  //   processAlert: sl(),
  //   behaviorMatrix: sl(),
  //   drillAnalyzer: sl(),
  // ));

  // ═══════════════════════════════════════════════════════════
  //  FEATURE: Comunicaciones
  // ═══════════════════════════════════════════════════════════

  // sl.registerLazySingleton<BridgefyDatasource>(
  //   () => BridgefyDatasourceImpl(),
  // );
  // sl.registerLazySingleton<SmsFallbackDatasource>(
  //   () => SmsFallbackDatasourceImpl(connectivity: sl()),
  // );
  // sl.registerFactory(() => CommunicationBloc(
  //   bridgefy: sl(),
  //   smsFallback: sl(),
  // ));
}
