// ============================================================================
// SismoGuard — Dashboard Principal
// ============================================================================
// Pantalla principal de la aplicación que muestra el estado del sistema
// en tiempo real: nivel de amenaza, estado de comunicaciones, última
// actividad sísmica, y acciones rápidas.
// ============================================================================

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Dashboard principal de SismoGuard.
///
/// Muestra:
/// - Indicador de nivel de amenaza actual (gauge)
/// - Estado de todos los canales de comunicación
/// - Últimos eventos sísmicos detectados
import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import '../../../../features/seismic_detection/domain/usecases/sta_lta_trigger.dart';
import '../../../../features/seismic_detection/data/datasources/telemetry_service.dart';

/// Dashboard principal de SISMO-PREV APP.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ─── Sensores & Detección en Tiempo Real ───
  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  final StaLtaTrigger _staLtaTrigger = StaLtaTrigger();
  late TelemetryService _telemetryService;

  double _currentPga = 0.001;
  double _currentRatio = 1.0;
  bool _isSeismicTriggered = false;
  String _threatLevel = 'NORMAL'; // NORMAL, ALERTA, EVACUACION

  bool _isMonitoring = true;
  int _connectedPeers = 1;
  final List<String> _activeChannels = ['tcp_ip', 'nearby_ble'];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Iniciar servicio de telemetría hacia el servidor
    _telemetryService = TelemetryService(
      serverBaseUrl: 'http://172.16.27.14:8080',
      nodeId: 'TEL-SISMOPREV-01',
      place: 'Muro Estructural - Sede Universitaria',
    );

    _iniciarMonitoreoAcelerometro();
  }

  void _iniciarMonitoreoAcelerometro() {
    try {
      _accelSub = userAccelerometerEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen((UserAccelerometerEvent event) {
        final now = DateTime.now().millisecondsSinceEpoch.toDouble();
        final result = _staLtaTrigger.processSample(event.x, event.y, event.z, now);

        final pga = sqrt(event.x * event.x + event.y * event.y + event.z * event.z) / 9.81;

        setState(() {
          _currentPga = pga;
          _currentRatio = result.ratio;
          _isSeismicTriggered = result.isTriggered;

          if (_isSeismicTriggered || pga > 0.08) {
            _threatLevel = 'EVACUACION';
          } else if (pga > 0.02) {
            _threatLevel = 'ALERTA';
          } else {
            _threatLevel = 'NORMAL';
          }
        });

        // Si se detecta trigger, enviar ráfaga inmediata
        if (result.isTriggered) {
          _telemetryService.sendTelemetry(
            pga: pga,
            staLtaRatio: result.ratio,
            isTriggered: true,
          );
        }
      });

      // Heartbeat cada 2s hacia el servidor
      _telemetryService.startHeartbeat(
        getCurrentPga: () => _currentPga,
        getCurrentRatio: () => _currentRatio,
        getIsTriggered: () => _isSeismicTriggered,
      );
    } catch (e) {
      // Manejo seguro en entornos sin sensor físico
    }
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _telemetryService.stop();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header con logo y estado ──
            SliverToBoxAdapter(child: _buildHeader()),

            // ── Indicador de nivel de amenaza ──
            SliverToBoxAdapter(child: _buildThreatLevelGauge()),

            // ── Estado de comunicaciones ──
            SliverToBoxAdapter(child: _buildCommunicationsStatus()),

            // ── Estado del sistema ──
            SliverToBoxAdapter(child: _buildSystemStatusCard()),

            // ── Últimos eventos ──
            SliverToBoxAdapter(child: _buildRecentEventsSection()),

            // ── Panel de acciones rápidas ──
            SliverToBoxAdapter(child: _buildQuickActions()),

            // Espaciado inferior
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  HEADER
  // ═══════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // Logo Oficial
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/logo.png',
              width: 44,
              height: 44,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shield_rounded, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Título y subtítulo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SISMO-PREV APP',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.darkTextPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Monitoreo & Resiliencia Sísmica',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Botón de configuración
          IconButton(
            onPressed: () {
              // TODO: Navegar a configuración
            },
            icon: const Icon(
              Icons.settings_rounded,
              color: AppColors.darkTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  INDICADOR DE NIVEL DE AMENAZA
  // ═══════════════════════════════════════════════════════════

  Widget _buildThreatLevelGauge() {
    Color statusColor;
    String statusTitle;
    IconData statusIcon;

    if (_threatLevel == 'EVACUACION') {
      statusColor = AppColors.severityExtreme;
      statusTitle = '¡ALERTA SÍSMICA: EVACUAR!';
      statusIcon = Icons.warning_rounded;
    } else if (_threatLevel == 'ALERTA') {
      statusColor = AppColors.severitySevere;
      statusTitle = 'ANOMALÍA DETECTADA';
      statusIcon = Icons.sensors_rounded;
    } else {
      statusColor = AppColors.statusActive;
      statusTitle = 'SIN AMENAZA DETECTADA';
      statusIcon = Icons.check_circle_rounded;
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: statusColor.withValues(
                alpha: _pulseAnimation.value * 0.7,
              ),
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: 0.2),
                blurRadius: 25 * _pulseAnimation.value,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withValues(alpha: 0.15),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.6),
                    width: 2.5,
                  ),
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 44,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                statusTitle,
                style: AppTypography.titleMedium.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),

              Text(
                'Aceleración actual (PGA): ${_currentPga.toStringAsFixed(3)} g | Ratio: ${_currentRatio.toStringAsFixed(1)}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.darkTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  ESTADO DE COMUNICACIONES
  // ═══════════════════════════════════════════════════════════

  Widget _buildCommunicationsStatus() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cell_tower_rounded,
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Canales de Comunicación',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.darkTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Grid de canales
          Row(
            children: [
              _buildChannelBadge(
                icon: Icons.wifi_rounded,
                label: 'Internet',
                color: AppColors.commInternet,
                isActive: true,
              ),
              const SizedBox(width: 8),
              _buildChannelBadge(
                icon: Icons.bluetooth_rounded,
                label: 'BLE Mesh',
                color: AppColors.commBluetooth,
                isActive: false,
              ),
              const SizedBox(width: 8),
              _buildChannelBadge(
                icon: Icons.radio_rounded,
                label: 'LoRa',
                color: AppColors.commLoRa,
                isActive: false,
              ),
              const SizedBox(width: 8),
              _buildChannelBadge(
                icon: Icons.sms_rounded,
                label: 'SMS',
                color: AppColors.commSms,
                isActive: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChannelBadge({
    required IconData icon,
    required String label,
    required Color color,
    required bool isActive,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.12)
              : AppColors.darkSurfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? color.withValues(alpha: 0.4) : AppColors.darkBorder,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 20,
                color: isActive ? color : AppColors.darkTextTertiary),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isActive ? color : AppColors.darkTextTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  ESTADO DEL SISTEMA
  // ═══════════════════════════════════════════════════════════

  Widget _buildSystemStatusCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monitor_heart_rounded,
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Estado del Sistema',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.darkTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildStatusRow(
            'Detección Sísmica',
            _isMonitoring ? 'Activa — 50Hz' : 'Inactiva',
            _isMonitoring ? AppColors.statusActive : AppColors.statusError,
          ),
          const SizedBox(height: 8),
          _buildStatusRow(
            'Algoritmo STA/LTA',
            'En ejecución',
            AppColors.statusActive,
          ),
          const SizedBox(height: 8),
          _buildStatusRow(
            'Modelo CNN',
            'Pendiente de modelo',
            AppColors.statusWarning,
          ),
          const SizedBox(height: 8),
          _buildStatusRow(
            'Mapas Offline',
            'No descargados',
            AppColors.statusInactive,
          ),
          const SizedBox(height: 8),
          _buildStatusRow(
            'Peers Mesh',
            '$_connectedPeers conectados',
            _connectedPeers > 0
                ? AppColors.statusActive
                : AppColors.statusInactive,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color statusColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor,
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.darkTextSecondary,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: AppTypography.labelSmall.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  EVENTOS RECIENTES
  // ═══════════════════════════════════════════════════════════

  Widget _buildRecentEventsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded,
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Actividad Reciente',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.darkTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Estado vacío
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.landscape_rounded,
                  size: 48,
                  color: AppColors.darkTextTertiary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sin actividad sísmica reciente',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.darkTextTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'El sistema está monitorizando continuamente',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.darkTextTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  ACCIONES RÁPIDAS
  // ═══════════════════════════════════════════════════════════

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acciones Rápidas',
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.darkTextPrimary,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              _buildActionButton(
                icon: Icons.map_rounded,
                label: 'Mapa\nOffline',
                color: AppColors.accent,
                onTap: () {
                  // TODO: Navegar a mapa offline
                },
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                icon: Icons.campaign_rounded,
                label: 'Iniciar\nSimulacro',
                color: AppColors.drillModeBorder,
                onTap: () {
                  // TODO: Iniciar simulacro
                },
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                icon: Icons.bluetooth_searching_rounded,
                label: 'Activar\nMesh',
                color: AppColors.commBluetooth,
                onTap: () {
                  // TODO: Activar red BLE Mesh
                },
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                icon: Icons.info_outline_rounded,
                label: 'Acerca\nde',
                color: AppColors.darkTextSecondary,
                onTap: () {
                  // TODO: Mostrar información
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
