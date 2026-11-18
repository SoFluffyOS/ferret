package io.sofluffy.ferret_power

import io.flutter.embedding.engine.plugins.FlutterPlugin

/** FerretPowerPlugin */
class FerretPowerPlugin :
    FlutterPlugin,
    FerretPowerPluginApi {
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        FerretPowerPluginApi.setUp(flutterPluginBinding.binaryMessenger, this)
    }

    override fun getPlatformVersion(): String = "Android ${android.os.Build.VERSION.RELEASE}"

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        FerretPowerPluginApi.setUp(binding.binaryMessenger, null)
    }
}
