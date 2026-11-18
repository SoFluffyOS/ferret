package io.sofluffy.ferret_mirroring

import io.flutter.embedding.engine.plugins.FlutterPlugin

/** FerretMirroringPlugin */
class FerretMirroringPlugin :
    FlutterPlugin,
    FerretMirroringPluginApi {
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        FerretMirroringPluginApi.setUp(flutterPluginBinding.binaryMessenger, this)
    }

    override fun getPlatformVersion(): String = "Android ${android.os.Build.VERSION.RELEASE}"

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        FerretMirroringPluginApi.setUp(binding.binaryMessenger, null)
    }
}
