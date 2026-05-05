package com.emcc.sistema_escolar

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.emcc.mesh.MeshPlugin

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.emcc.mesh/channel"
    private lateinit var meshPlugin: MeshPlugin

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        meshPlugin = MeshPlugin(context)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startServer" -> {
                    val port = call.argument<Int>("port") ?: 8080
                    meshPlugin.startServer(port)
                    result.success(true)
                }
                "discoverPeers" -> {
                    meshPlugin.startDiscovery()
                    result.success(emptyList<String>())
                }
                "sendToAll" -> {
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
