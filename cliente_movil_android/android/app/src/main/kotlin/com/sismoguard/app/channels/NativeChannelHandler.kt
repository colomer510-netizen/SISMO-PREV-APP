// ============================================================================
// SismoGuard — Manejador de Canales Nativos (NativeChannelHandler)
// ============================================================================
// Configura todos los Method Channels y Event Channels para la comunicación
// bidireccional entre Dart y el código nativo Kotlin.
// Se inicializa desde MainActivity.
// ============================================================================

package com.sismoguard.app.channels

import android.content.Context
import android.content.Intent
import android.os.Build
import android.hardware.Sensor
import android.hardware.SensorManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.sismoguard.app.services.SeismicForegroundService

/**
 * Manejador centralizado de todos los canales de comunicación Dart ↔ Nativo.
 *
 * Registra:
 * - Method Channels para RPC (Dart invoca funcionalidad nativa)
 * - Event Channels para streams continuos (Nativo envía datos a Dart)
 */
class NativeChannelHandler(
    private val context: Context,
    private val flutterEngine: FlutterEngine
) {
    companion object {
        // ─── Nombres de Canales (deben coincidir con channel_constants.dart) ───
        const val FOREGROUND_SERVICE_CHANNEL = "com.sismoguard.app/foreground_service"
        const val ACCELEROMETER_CHANNEL = "com.sismoguard.app/accelerometer"
        const val DEVICE_CONTROL_CHANNEL = "com.sismoguard.app/device_control"
        const val SMS_FALLBACK_CHANNEL = "com.sismoguard.app/sms_fallback"
        const val ACCELEROMETER_STREAM = "com.sismoguard.app/accelerometer_stream"
        const val SERVICE_STATUS_STREAM = "com.sismoguard.app/service_status_stream"
        const val CELL_BROADCAST_STREAM = "com.sismoguard.app/cell_broadcast_stream"
    }

    // ─── Streams Activos ───
    private var accelerometerEventSink: EventChannel.EventSink? = null
    private var serviceStatusEventSink: EventChannel.EventSink? = null

    /**
     * Inicializa todos los canales de comunicación.
     * Debe llamarse desde `configureFlutterEngine` en MainActivity.
     */
    fun initialize() {
        setupForegroundServiceChannel()
        setupAccelerometerChannel()
        setupDeviceControlChannel()
        setupSmsFallbackChannel()
        setupAccelerometerStreamChannel()
        setupServiceStatusStreamChannel()
        setupCellBroadcastStreamChannel()
    }

    // ═══════════════════════════════════════════════════════════
    //  METHOD CHANNEL: Foreground Service
    // ═══════════════════════════════════════════════════════════

    private fun setupForegroundServiceChannel() {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            FOREGROUND_SERVICE_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    try {
                        val sampleRateHz = call.argument<Int>("sampleRateHz") ?: 50
                        val enableWakeLock = call.argument<Boolean>("enableWakeLock") ?: true

                        val serviceIntent = Intent(context, SeismicForegroundService::class.java).apply {
                            putExtra("sampleRateHz", sampleRateHz)
                            putExtra("enableWakeLock", enableWakeLock)
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            context.startForegroundService(serviceIntent)
                        } else {
                            context.startService(serviceIntent)
                        }

                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SERVICE_START_ERROR", e.message, null)
                    }
                }

                "stopService" -> {
                    try {
                        val serviceIntent = Intent(context, SeismicForegroundService::class.java)
                        context.stopService(serviceIntent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SERVICE_STOP_ERROR", e.message, null)
                    }
                }

                "isRunning" -> {
                    result.success(SeismicForegroundService.isRunning)
                }

                "updateNotification" -> {
                    val title = call.argument<String>("title") ?: "SismoGuard"
                    val body = call.argument<String>("body") ?: "Monitorizando..."
                    // La actualización de notificación se maneja internamente
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    // ═══════════════════════════════════════════════════════════
    //  METHOD CHANNEL: Acelerómetro
    // ═══════════════════════════════════════════════════════════

    private fun setupAccelerometerChannel() {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ACCELEROMETER_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setSampleRate" -> {
                    val rateHz = call.argument<Int>("rateHz") ?: 50
                    // En una implementación completa, esto reconfiguraría
                    // el listener del SensorManager con el nuevo período.
                    result.success(true)
                }

                "calibrate" -> {
                    // Stub de calibración: retorna offsets cero.
                    // En producción, promediar muestras en reposo.
                    result.success(mapOf(
                        "x" to 0.0,
                        "y" to 0.0,
                        "z" to 0.0
                    ))
                }

                "getDeviceSensorInfo" -> {
                    val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
                    val accel = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

                    if (accel != null) {
                        result.success(mapOf(
                            "name" to accel.name,
                            "vendor" to accel.vendor,
                            "version" to accel.version,
                            "maxRange" to accel.maximumRange.toDouble(),
                            "resolution" to accel.resolution.toDouble(),
                            "power" to accel.power.toDouble(),
                            "minDelay" to accel.minDelay, // microsegundos
                            "maxDelay" to accel.maxDelay,
                            "isWakeUpSensor" to accel.isWakeUpSensor
                        ))
                    } else {
                        result.error("SENSOR_NOT_FOUND", "Acelerómetro no disponible", null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    // ═══════════════════════════════════════════════════════════
    //  METHOD CHANNEL: Control de Dispositivo (Alarmas)
    // ═══════════════════════════════════════════════════════════

    private fun setupDeviceControlChannel() {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DEVICE_CONTROL_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setVolume" -> {
                    val volume = call.argument<Int>("volume") ?: 100
                    // TODO: Implementar control de volumen via AudioManager
                    // val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    // val maxVol = audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM)
                    // audioManager.setStreamVolume(AudioManager.STREAM_ALARM, (maxVol * volume / 100), 0)
                    result.success(true)
                }

                "setVibrationPattern" -> {
                    val pattern = call.argument<List<Long>>("pattern") ?: listOf(0L, 500L)
                    // TODO: Implementar via Vibrator
                    result.success(true)
                }

                "wakeScreen" -> {
                    // TODO: Implementar PowerManager.ACQUIRE_CAUSES_WAKEUP
                    result.success(true)
                }

                "activateSiren" -> {
                    val level = call.argument<Int>("severityLevel") ?: 1
                    // TODO: Implementar reproducción de alarma según nivel
                    result.success(true)
                }

                "deactivateSiren" -> {
                    // TODO: Detener reproducción de alarma
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    // ═══════════════════════════════════════════════════════════
    //  METHOD CHANNEL: SMS Fallback
    // ═══════════════════════════════════════════════════════════

    private fun setupSmsFallbackChannel() {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SMS_FALLBACK_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "sendSilentSms" -> {
                    val phoneNumber = call.argument<String>("phoneNumber")
                    val payload = call.argument<String>("payload")

                    if (phoneNumber != null && payload != null) {
                        try {
                            // Enviar SMS silencioso via SmsManager
                            val smsManager = android.telephony.SmsManager.getDefault()
                            smsManager.sendTextMessage(
                                phoneNumber,
                                null,      // scAddress
                                payload,
                                null,      // sentIntent
                                null       // deliveryIntent
                            )
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SMS_SEND_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "phoneNumber y payload son requeridos", null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    // ═══════════════════════════════════════════════════════════
    //  EVENT CHANNEL: Stream del Acelerómetro
    // ═══════════════════════════════════════════════════════════

    private fun setupAccelerometerStreamChannel() {
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ACCELEROMETER_STREAM
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                accelerometerEventSink = events
                // Aquí se conectaría el callback del SeismicForegroundService
                // para enviar cada muestra del acelerómetro al EventSink.
            }

            override fun onCancel(arguments: Any?) {
                accelerometerEventSink = null
            }
        })
    }

    /**
     * Envía un dato del acelerómetro al stream de Dart.
     * Llamado desde el SeismicForegroundService cada ~20ms.
     */
    fun emitAccelerometerData(data: Map<String, Any>) {
        accelerometerEventSink?.success(data)
    }

    // ═══════════════════════════════════════════════════════════
    //  EVENT CHANNEL: Estado del Servicio
    // ═══════════════════════════════════════════════════════════

    private fun setupServiceStatusStreamChannel() {
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SERVICE_STATUS_STREAM
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                serviceStatusEventSink = events
            }

            override fun onCancel(arguments: Any?) {
                serviceStatusEventSink = null
            }
        })
    }

    /**
     * Envía un evento de estado del servicio a Dart.
     */
    fun emitServiceStatus(status: Map<String, Any>) {
        serviceStatusEventSink?.success(status)
    }

    // ═══════════════════════════════════════════════════════════
    //  EVENT CHANNEL: Cell Broadcast (Stub)
    // ═══════════════════════════════════════════════════════════

    private fun setupCellBroadcastStreamChannel() {
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CELL_BROADCAST_STREAM
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                // TODO: Registrar ContentObserver para mensajes Cell Broadcast
                // del sistema y emitir eventos cuando se reciban.
            }

            override fun onCancel(arguments: Any?) {
                // TODO: Desregistrar ContentObserver
            }
        })
    }

    /**
     * Limpia todos los recursos al destruir el engine.
     */
    fun dispose() {
        accelerometerEventSink = null
        serviceStatusEventSink = null
    }
}
