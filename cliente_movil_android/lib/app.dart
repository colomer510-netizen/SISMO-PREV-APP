// ============================================================================
// SismoGuard — Configuración de la Aplicación
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'injection_container.dart';

/// Widget raíz de la aplicación SismoGuard.
///
/// Configura:
/// - Tema visual (modo oscuro por defecto para emergencias nocturnas)
/// - Proveedores BLoC globales
/// - Rutas de navegación
class SismoGuardApp extends StatelessWidget {
  const SismoGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Los BLoCs globales se inyectarán aquí conforme se implementen.
        // Ejemplo:
        // BlocProvider(create: (_) => sl<SeismicBloc>()),
        // BlocProvider(create: (_) => sl<AlertBloc>()),
        // BlocProvider(create: (_) => sl<CommunicationBloc>()),
      ],
      child: MaterialApp(
        title: 'SismoGuard',
        debugShowCheckedModeBanner: false,

        // ── Tema visual ──
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark, // Modo oscuro por defecto

        // ── Ruta inicial ──
        home: const DashboardPage(),

        // ── Rutas nombradas ──
        routes: _buildRoutes(),
      ),
    );
  }

  /// Construye el mapa de rutas de la aplicación.
  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/dashboard': (context) => const DashboardPage(),
      // Se agregarán más rutas conforme se implementen las features:
      // '/seismic-monitor': (context) => const SeismicMonitorPage(),
      // '/map': (context) => const MapPage(),
      // '/alert-detail': (context) => const AlertDetailPage(),
    };
  }
}
