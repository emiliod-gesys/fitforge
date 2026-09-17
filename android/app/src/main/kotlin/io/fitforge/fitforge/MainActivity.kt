package io.fitforge.fitforge

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Android 15 (SDK 35) dibuja de borde a borde por defecto; esto alinea
        // también Android 14 y evita que las barras tapen la UI.
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        WearSessionBridge(this, flutterEngine.dartExecutor.binaryMessenger)
    }
}
