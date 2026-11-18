package io.sofluffy.ferret_remote_input

import io.flutter.embedding.engine.plugins.FlutterPlugin

/** FerretRemoteInputPlugin */
class FerretRemoteInputPlugin :
    FlutterPlugin,
    FerretRemoteInputPluginApi {
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        FerretRemoteInputPluginApi.setUp(flutterPluginBinding.binaryMessenger, this)
    }

    override fun getPlatformVersion(): String = "Android ${android.os.Build.VERSION.RELEASE}"

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        FerretRemoteInputPluginApi.setUp(binding.binaryMessenger, null)
    }
}
