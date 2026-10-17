// ============================================================================
// SismoGuard — MainActivity
// ============================================================================
// Activity principal de Flutter. Configura los canales nativos al inicializar
// el FlutterEngine.
// ============================================================================

package com.sismoguard.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.sismoguard.app.channels.NativeChannelHandler

class MainActivity : FlutterActivity() {
    private var channelHandler: NativeChannelHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Inicializar todos los canales de comunicación Dart ↔ Nativo
        channelHandler = NativeChannelHandler(this, flutterEngine).also {
            it.initialize()
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        channelHandler?.dispose()
        channelHandler = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
