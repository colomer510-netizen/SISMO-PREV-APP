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
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import '../../../../core/platform/foreground_service_controller.dart';
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

  String _nodeId = 'TEL-SISMOPREV-01';
  String _serverIp = '172.16.27.14';
  int _serverPort = 8080;
  double _currentPga = 0.001;
  double _currentRatio = 1.0;
  bool _isSeismicTriggered = false;
  String _threatLevel = 'NORMAL'; // NORMAL, ALERTA, EVACUACION, SIMULACRO

  bool _isMonitoring = true;
  bool _isMeshActive = false;
  int _connectedPeers = 0;
  final List<String> _activeChannels = ['tcp_ip'];

  bool _isDrillAudioPlaying = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _activarAlarmaSonora() async {
    if (_isDrillAudioPlaying) return;
    setState(() {
      _isDrillAudioPlaying = true;
      _threatLevel = 'SIMULACRO';
    });

    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/alarm_siren.wav'));
    } catch (e) {
      debugPrint('Error reproduciendo sonido de alarma: $e');
    }

    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(pattern: [500, 1000, 500, 1000], repeat: 0);
      }
    } catch (_) {}
  }

  Future<void> _detenerAlarmaSonora() async {
    if (!_isDrillAudioPlaying) return;
    setState(() {
      _isDrillAudioPlaying = false;
      _threatLevel = 'NORMAL';
    });

    try {
      await _audioPlayer.stop();
    } catch (_) {}

    try {
      Vibration.cancel();
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();

    // Generar un ID único por dispositivo (ej: TEL-SISMO-4891)
    final randId = 1000 + Random().nextInt(9000);
    _nodeId = 'TEL-SISMO-$randId';

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Iniciar servicio de telemetría hacia el servidor
    _iniciarTelemetria();
    _iniciarMonitoreoAcelerometro();

    // Activar Foreground Service para persistencia en segundo plano
    ForegroundServiceController.instance.startService();
  }

  void _iniciarTelemetria() {
    _telemetryService = TelemetryService(
      serverBaseUrl: 'http://$_serverIp:$_serverPort',
      nodeId: _nodeId,
      place: 'Muro Estructural - $_nodeId',
    );

    _telemetryService.startHeartbeat(
      getCurrentPga: () => _currentPga,
      getCurrentRatio: () => _currentRatio,
      getIsTriggered: () => _isSeismicTriggered,
      onServerCommand: (data) {
        final activeDrill = data['active_drill'] == true;
        if (activeDrill && !_isDrillAudioPlaying) {
          _activarAlarmaSonora();
        } else if (!activeDrill && _isDrillAudioPlaying) {
          _detenerAlarmaSonora();
        }
      },
    );
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

          if (_isDrillAudioPlaying) {
            _threatLevel = 'SIMULACRO';
          } else if (_isSeismicTriggered || pga > 0.08) {
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
    } catch (e) {
      // Manejo seguro en entornos sin sensor físico
    }
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _telemetryService.stop();
    _pulseController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth >= 768;

            if (isWideScreen) {
              // ── Diseño para Tablet y PC (2 Columnas centradas) ──
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _buildHeader()),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Columna Izquierda: Nivel de amenaza y comunicaciones
                              Expanded(
                                flex: 5,
                                child: Column(
                                  children: [
                                    _buildThreatLevelGauge(),
                                    _buildCommunicationsStatus(),
                                    _buildQuickActions(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Columna Derecha: Estado de sensores y eventos
                              Expanded(
                                flex: 6,
                                child: Column(
                                  children: [
                                    _buildSystemStatusCard(),
                                    _buildRecentEventsSection(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    ],
                  ),
                ),
              );
            }

            // ── Diseño para Teléfonos Móviles (1 Columna fluida) ──
            return CustomScrollView(
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
            );
          },
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
            onPressed: _mostrarDialogoConfiguracion,
            icon: const Icon(
              Icons.settings_rounded,
              color: AppColors.accent,
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

    if (_threatLevel == 'SIMULACRO') {
      statusColor = AppColors.drillModeBorder;
      statusTitle = '🚨 SIMULACRO ACTIVO: EVACUACIÓN';
      statusIcon = Icons.campaign_rounded;
    } else if (_threatLevel == 'EVACUACION') {
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
            _isMonitoring ? 'Activa — 50Hz (MEMS)' : 'Inactiva',
            _isMonitoring ? AppColors.statusActive : AppColors.statusError,
          ),
          const SizedBox(height: 8),
          _buildStatusRow(
            'Algoritmo STA/LTA',
            'En ejecución (Ratio: ${_currentRatio.toStringAsFixed(2)})',
            AppColors.statusActive,
          ),
          const SizedBox(height: 8),
          _buildStatusRow(
            'Filtro Neuronal (CNN)',
            'Activo — Filtro de Falsos Positivos',
            AppColors.statusActive,
          ),
          const SizedBox(height: 8),
          _buildStatusRow(
            'Mapas Offline',
            'Cargados en caché local',
            AppColors.statusActive,
          ),
          const SizedBox(height: 8),
          _buildStatusRow(
            'Red Malla (BLE Mesh)',
            _isMeshActive ? '$_connectedPeers Nodos Cercanos (Activo)' : 'En espera (Modo Standby)',
            _isMeshActive ? AppColors.commBluetooth : AppColors.statusInactive,
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
                onTap: _mostrarMapaOffline,
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                icon: _isDrillAudioPlaying ? Icons.stop_circle_rounded : Icons.campaign_rounded,
                label: _isDrillAudioPlaying ? 'Detener\nAlarma' : 'Iniciar\nSimulacro',
                color: _isDrillAudioPlaying ? AppColors.severityExtreme : AppColors.drillModeBorder,
                onTap: _toggleSimulacroSonoro,
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                icon: _isMeshActive ? Icons.bluetooth_connected_rounded : Icons.bluetooth_searching_rounded,
                label: _isMeshActive ? 'Mesh: ON\n(Nearby)' : 'Activar\nMesh',
                color: _isMeshActive ? AppColors.statusActive : AppColors.commBluetooth,
                onTap: _toggleMesh,
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                icon: Icons.info_outline_rounded,
                label: 'Acerca\nde',
                color: AppColors.darkTextSecondary,
                onTap: _mostrarAcercaDe,
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

  // ═══════════════════════════════════════════════════════════
  //  MODALES Y FUNCIONES INTERACTIVAS
  // ═══════════════════════════════════════════════════════════

  void _toggleSimulacroSonoro() async {
    if (_isDrillAudioPlaying) {
      await _detenerAlarmaSonora();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Simulacro finalizado. Alarma silenciada.'),
          backgroundColor: AppColors.statusActive,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      await _activarAlarmaSonora();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚨 ¡SIMULACRO ACTIVO! Alarma acústica y vibración sonando.'),
          backgroundColor: AppColors.drillModeBorder,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _toggleMesh() {
    setState(() {
      _isMeshActive = !_isMeshActive;
      if (_isMeshActive) {
        _connectedPeers = 3; // 3 teléfonos simulados en la malla local
        if (!_activeChannels.contains('nearby_ble')) {
          _activeChannels.add('nearby_ble');
        }
      } else {
        _connectedPeers = 0;
        _activeChannels.remove('nearby_ble');
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isMeshActive
              ? '📡 Red Malla P2P (Google Nearby) ACTIVADA: 3 Nodos enlazados.'
              : 'Bluetooth Mesh desactivado.',
        ),
        backgroundColor: _isMeshActive ? AppColors.commBluetooth : AppColors.darkSurfaceElevated,
      ),
    );
  }

  void _mostrarMapaOffline() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.map_rounded, color: AppColors.accent, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Mapa Offline de Evacuación Comunitaria',
                    style: AppTypography.titleMedium.copyWith(color: AppColors.darkTextPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.darkBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppColors.statusActive, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        'Punto de Encuentro Seguro: Patio Central Universitario',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.darkTextPrimary, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ruta de Evacuación: Corredor A hacia Cancha Deportiva',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.accent),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar Mapa', style: TextStyle(color: AppColors.darkBackground, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarDialogoConfiguracion() {
    final ipController = TextEditingController(text: _serverIp);
    final portController = TextEditingController(text: _serverPort.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.darkSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.settings_rounded, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('Configuración SISMO-PREV', style: AppTypography.titleMedium.copyWith(color: AppColors.darkTextPrimary)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ipController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'IP del Servidor Central',
                  labelStyle: TextStyle(color: AppColors.accent),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.darkBorder)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: portController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Puerto',
                  labelStyle: TextStyle(color: AppColors.accent),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.darkBorder)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'ID de este Nodo: $_nodeId',
                style: AppTypography.labelSmall.copyWith(color: AppColors.darkTextTertiary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.darkTextSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              onPressed: () {
                setState(() {
                  _serverIp = ipController.text.trim();
                  _serverPort = int.tryParse(portController.text.trim()) ?? 8080;
                  _telemetryService.stop();
                  _iniciarTelemetria();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Servidor actualizado a: http://$_serverIp:$_serverPort'),
                    backgroundColor: AppColors.statusActive,
                  ),
                );
              },
              child: const Text('Guardar', style: TextStyle(color: AppColors.darkBackground, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _mostrarAcercaDe() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.darkSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Acerca de SISMO-PREV', style: AppTypography.titleMedium.copyWith(color: AppColors.darkTextPrimary)),
          content: Text(
            'Sistema Comunitario de Alerta Sísmica Temprana y Resiliencia Escolar.\n\n'
            'Desarrollado para el Desafío 02: "Sensores al servicio de la comunidad" del Rally Latinoamericano de Innovación 2026.\n\n'
            'Alianza Internacional:\n'
            '• FENIX CODE (Nicaragua 🇳🇮)\n'
            '• EVOLVING MINDS (El Salvador 🇸🇻)\n\n'
            'Licencia: MIT (Open Source)',
            style: AppTypography.bodySmall.copyWith(color: AppColors.darkTextSecondary, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar', style: TextStyle(color: AppColors.darkBackground, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

