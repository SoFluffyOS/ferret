package io.sofluffy.ferret_handoff

import io.flutter.embedding.engine.plugins.FlutterPlugin

/** FerretHandoffPlugin */
class FerretHandoffPlugin :
    FlutterPlugin,
    FerretHandoffPluginApi {
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        FerretHandoffPluginApi.setUp(flutterPluginBinding.binaryMessenger, this)
    }

    override fun getPlatformVersion(): String = "Android ${android.os.Build.VERSION.RELEASE}"

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        FerretHandoffPluginApi.setUp(binding.binaryMessenger, null)
    }
}
