package io.sofluffy.ferret_calls

import io.flutter.embedding.engine.plugins.FlutterPlugin

/** FerretCallsPlugin */
class FerretCallsPlugin :
    FlutterPlugin,
    FerretCallsPluginApi {
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        FerretCallsPluginApi.setUp(flutterPluginBinding.binaryMessenger, this)
    }

    override fun getPlatformVersion(): String = "Android ${android.os.Build.VERSION.RELEASE}"

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        FerretCallsPluginApi.setUp(binding.binaryMessenger, null)
    }
}
