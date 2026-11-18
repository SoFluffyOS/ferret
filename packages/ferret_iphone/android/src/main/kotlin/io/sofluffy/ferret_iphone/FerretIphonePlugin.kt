package io.sofluffy.ferret_iphone

import io.flutter.embedding.engine.plugins.FlutterPlugin

/** FerretIphonePlugin */
class FerretIphonePlugin :
    FlutterPlugin,
    FerretIphonePluginApi {
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        FerretIphonePluginApi.setUp(flutterPluginBinding.binaryMessenger, this)
    }

    override fun getPlatformVersion(): String = "Android ${android.os.Build.VERSION.RELEASE}"

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        FerretIphonePluginApi.setUp(binding.binaryMessenger, null)
    }
}
