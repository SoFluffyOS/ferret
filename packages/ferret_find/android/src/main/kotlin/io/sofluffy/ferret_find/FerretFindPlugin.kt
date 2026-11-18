package io.sofluffy.ferret_find

import io.flutter.embedding.engine.plugins.FlutterPlugin

/** FerretFindPlugin */
class FerretFindPlugin :
    FlutterPlugin,
    FerretFindPluginApi {
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        FerretFindPluginApi.setUp(flutterPluginBinding.binaryMessenger, this)
    }

    override fun getPlatformVersion(): String = "Android ${android.os.Build.VERSION.RELEASE}"

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        FerretFindPluginApi.setUp(binding.binaryMessenger, null)
    }
}
