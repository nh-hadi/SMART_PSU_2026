package com.example.smartpsu

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.smartpsu/screen_manager"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Default: Jaga layar tetap aktif saat aplikasi terbuka
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "keepOn" -> {
                    val enable = call.argument<Boolean>("enable") ?: true
                    if (enable) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    }
                    result.success(true)
                }
                "setDimLevel" -> {
                    // Atur brightness layar: -1.0 (default sistem), 0.01 (sangat redup), 1.0 (terang penuh)
                    val brightness = call.argument<Double>("brightness")?.toFloat() ?: -1.0f
                    val layout = window.attributes
                    layout.screenBrightness = brightness
                    window.attributes = layout
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
