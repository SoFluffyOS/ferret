package io.sofluffy.ferret_drop

import io.flutter.embedding.engine.plugins.FlutterPlugin

/** FerretDropPlugin */
class FerretDropPlugin :
    FlutterPlugin,
    FerretDropPluginApi {
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        FerretDropPluginApi.setUp(flutterPluginBinding.binaryMessenger, this)
    }

    override fun getPlatformVersion(): String = "Android ${android.os.Build.VERSION.RELEASE}"

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        FerretDropPluginApi.setUp(binding.binaryMessenger, null)
    }
}
