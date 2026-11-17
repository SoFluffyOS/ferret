package io.sofluffy.ferret_media

import io.flutter.embedding.engine.plugins.FlutterPlugin

/** FerretMediaPlugin */
class FerretMediaPlugin :
    FlutterPlugin,
    FerretMediaPluginApi {
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        FerretMediaPluginApi.setUp(flutterPluginBinding.binaryMessenger, this)
    }

    override fun getPlatformVersion(): String = "Android ${android.os.Build.VERSION.RELEASE}"

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        FerretMediaPluginApi.setUp(binding.binaryMessenger, null)
    }
}
