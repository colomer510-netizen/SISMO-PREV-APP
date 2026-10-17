// ============================================================================
// SismoGuard — Foreground Service Nativo para Detección Sísmica
// ============================================================================
// Servicio de primer plano en Kotlin que:
// 1. Mantiene un WakeLock parcial para resistir Doze Mode
// 2. Registra el acelerómetro MEMS a SENSOR_DELAY_GAME (~50Hz)
// 3. Almacena muestras en un buffer circular
// 4. Envía datos a Dart via EventChannel
// 5. Muestra una notificación persistente con estado del monitoreo
// ============================================================================

package com.sismoguard.app.services

import android.app.*
import android.content.Context
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.*
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat

/**
 * Servicio de primer plano para detección sísmica continua.
 *
 * Este servicio es el corazón del sistema de detección de SismoGuard.
 * Opera con un WakeLock parcial para garantizar que el monitoreo
 * del acelerómetro no se interrumpa, incluso cuando el dispositivo
 * entra en Doze Mode o App Standby.
 *
 * Flujo de datos:
 * Acelerómetro MEMS → SensorEventListener → Buffer Circular → EventChannel → Dart
 */
class SeismicForegroundService : Service(), SensorEventListener {

    companion object {
        // ─── Constantes del Canal de Notificación ───
        const val CHANNEL_ID = "sismoguard_seismic_detection"
        const val CHANNEL_NAME = "Detección Sísmica"
        const val NOTIFICATION_ID = 1001

        // ─── Constantes del Acelerómetro ───
        const val DEFAULT_SAMPLE_RATE_HZ = 50
        const val BUFFER_SIZE = 5000 // ~100 segundos a 50Hz

        // ─── Constantes del WakeLock ───
        const val WAKE_LOCK_TAG = "SismoGuard::SeismicDetection"

        // ─── Estado del Servicio ───
        @Volatile
        var isRunning = false
            private set
    }

    // ─── Componentes del Sistema ───
    private lateinit var sensorManager: SensorManager
    private var accelerometer: Sensor? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var handlerThread: HandlerThread? = null
    private var sensorHandler: Handler? = null

    // ─── Buffer Circular de Muestras ───
    // Cada muestra: [x, y, z, timestamp]
    private val sampleBuffer = ArrayDeque<FloatArray>(BUFFER_SIZE)
    private val bufferLock = Any()

    // ─── Configuración ───
    private var sampleRateHz = DEFAULT_SAMPLE_RATE_HZ
    private var sampleCount: Long = 0

    // ─── Callback para enviar datos a Dart (se configura desde NativeChannelHandler) ───
    var onSensorData: ((Map<String, Any>) -> Unit)? = null

    // ═══════════════════════════════════════════════════════════
    //  CICLO DE VIDA DEL SERVICIO
    // ═══════════════════════════════════════════════════════════

    override fun onCreate() {
        super.onCreate()

        // Inicializar el SensorManager
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

        // Crear un HandlerThread dedicado para el procesamiento del sensor
        // Esto evita bloquear el hilo principal con el stream de datos
        handlerThread = HandlerThread("SeismicSensorThread", Process.THREAD_PRIORITY_URGENT_AUDIO).also {
            it.start()
            sensorHandler = Handler(it.looper)
        }

        // Crear el canal de notificación (requerido para Android 8.0+)
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Obtener la tasa de muestreo del intent (o usar la predeterminada)
        sampleRateHz = intent?.getIntExtra("sampleRateHz", DEFAULT_SAMPLE_RATE_HZ)
            ?: DEFAULT_SAMPLE_RATE_HZ

        val enableWakeLock = intent?.getBooleanExtra("enableWakeLock", true) ?: true

        // Iniciar como Foreground Service con notificación persistente
        startForeground(NOTIFICATION_ID, buildNotification("Iniciando monitoreo..."))

        // Adquirir WakeLock parcial para resistir Doze Mode
        if (enableWakeLock) {
            acquireWakeLock()
        }

        // Registrar el listener del acelerómetro
        startAccelerometerCapture()

        isRunning = true

        // START_STICKY: el sistema reiniciará el servicio si es destruido
        return START_STICKY
    }

    override fun onDestroy() {
        stopAccelerometerCapture()
        releaseWakeLock()

        handlerThread?.quitSafely()
        handlerThread = null
        sensorHandler = null

        isRunning = false
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // ═══════════════════════════════════════════════════════════
    //  ACELERÓMETRO — Captura Continua
    // ═══════════════════════════════════════════════════════════

    /**
     * Inicia la captura del acelerómetro a la tasa de muestreo configurada.
     *
     * Usa SENSOR_DELAY_GAME (~20ms / ~50Hz) como base y configura
     * el período de muestreo exacto usando [SensorManager.registerListener]
     * con el parámetro de período en microsegundos.
     */
    private fun startAccelerometerCapture() {
        accelerometer?.let { sensor ->
            // Calcular el período de muestreo en microsegundos
            // 50Hz = 20,000 μs entre muestras
            val samplingPeriodUs = 1_000_000 / sampleRateHz

            // Registrar el listener con el período específico
            // El Handler dedicado asegura que los callbacks no bloqueen el hilo principal
            sensorManager.registerListener(
                this,
                sensor,
                samplingPeriodUs,
                samplingPeriodUs, // maxReportLatencyUs = mismo valor para mínima latencia
                sensorHandler
            )

            updateNotification("Monitorizando a ${sampleRateHz}Hz")
        } ?: run {
            updateNotification("⚠ Acelerómetro no disponible")
        }
    }

    /**
     * Detiene la captura del acelerómetro.
     */
    private fun stopAccelerometerCapture() {
        sensorManager.unregisterListener(this)
    }

    // ═══════════════════════════════════════════════════════════
    //  SENSOR EVENT LISTENER
    // ═══════════════════════════════════════════════════════════

    /**
     * Callback invocado cada vez que el acelerómetro produce un nuevo dato.
     *
     * A 50Hz, esto se ejecuta cada ~20ms. El procesamiento debe ser
     * extremadamente ligero para no perder muestras.
     */
    override fun onSensorChanged(event: SensorEvent?) {
        event ?: return
        if (event.sensor.type != Sensor.TYPE_ACCELEROMETER) return

        val x = event.values[0]
        val y = event.values[1]
        val z = event.values[2]
        val timestamp = event.timestamp // nanosegundos desde el boot

        // Almacenar en el buffer circular (thread-safe)
        synchronized(bufferLock) {
            if (sampleBuffer.size >= BUFFER_SIZE) {
                sampleBuffer.removeFirst()
            }
            sampleBuffer.addLast(floatArrayOf(x, y, z, timestamp.toFloat()))
        }

        sampleCount++

        // Enviar datos a Dart via callback
        onSensorData?.invoke(mapOf(
            "x" to x.toDouble(),
            "y" to y.toDouble(),
            "z" to z.toDouble(),
            "timestamp" to timestamp.toDouble(),
            "sampleCount" to sampleCount.toDouble()
        ))

        // Actualizar la notificación cada 500 muestras (~10 segundos)
        if (sampleCount % 500 == 0L) {
            val magnitude = Math.sqrt(
                (x * x + y * y + z * z).toDouble()
            )
            updateNotification(
                String.format("Activo | %.1f m/s² | %d muestras", magnitude, sampleCount)
            )
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // Log de cambios de precisión del sensor (para diagnóstico)
    }

    // ═══════════════════════════════════════════════════════════
    //  BUFFER — Acceso a datos históricos
    // ═══════════════════════════════════════════════════════════

    /**
     * Retorna las últimas N muestras del buffer como lista.
     * Usado por el algoritmo STA/LTA para analizar ventanas de datos.
     */
    fun getLastSamples(count: Int): List<FloatArray> {
        synchronized(bufferLock) {
            val available = minOf(count, sampleBuffer.size)
            return sampleBuffer.toList().takeLast(available)
        }
    }

    /**
     * Retorna el tamaño actual del buffer.
     */
    fun getBufferSize(): Int {
        synchronized(bufferLock) {
            return sampleBuffer.size
        }
    }

    // ═══════════════════════════════════════════════════════════
    //  WAKELOCK — Resistencia a Doze Mode
    // ═══════════════════════════════════════════════════════════

    /**
     * Adquiere un WakeLock parcial para mantener la CPU activa.
     *
     * PARTIAL_WAKE_LOCK mantiene la CPU funcionando pero permite
     * que la pantalla y el teclado se apaguen. Es el tipo menos
     * invasivo que garantiza la ejecución continua del servicio.
     */
    private fun acquireWakeLock() {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            WAKE_LOCK_TAG
        ).apply {
            // Adquirir sin timeout (el servicio controla la liberación)
            acquire()
        }
    }

    /**
     * Libera el WakeLock al detener el servicio.
     */
    private fun releaseWakeLock() {
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
            }
        }
        wakeLock = null
    }

    // ═══════════════════════════════════════════════════════════
    //  NOTIFICACIÓN PERSISTENTE
    // ═══════════════════════════════════════════════════════════

    /**
     * Crea el canal de notificación (requerido desde Android 8.0).
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW // LOW para no producir sonido
            ).apply {
                description = "SismoGuard está monitorizando actividad sísmica."
                setShowBadge(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    /**
     * Construye la notificación persistente del Foreground Service.
     */
    private fun buildNotification(contentText: String): Notification {
        // Intent para abrir la app al tocar la notificación
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("🛡 SismoGuard — Protección Activa")
            .setContentText(contentText)
            .setSmallIcon(android.R.drawable.ic_dialog_alert) // Temporal; reemplazar con ícono custom
            .setOngoing(true) // No descartable
            .setOnlyAlertOnce(true) // No repetir sonido al actualizar
            .setSilent(true) // Sin sonido ni vibración para la notificación
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(pendingIntent)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
    }

    /**
     * Actualiza el texto de la notificación sin recrearla.
     */
    private fun updateNotification(contentText: String) {
        val notification = buildNotification(contentText)
        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager.notify(NOTIFICATION_ID, notification)
    }
}
