package io.sofluffy.ferret_messages

import io.flutter.embedding.engine.plugins.FlutterPlugin

/** FerretMessagesPlugin */
class FerretMessagesPlugin :
    FlutterPlugin,
    FerretMessagesPluginApi {
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        FerretMessagesPluginApi.setUp(flutterPluginBinding.binaryMessenger, this)
    }

    override fun getPlatformVersion(): String = "Android ${android.os.Build.VERSION.RELEASE}"

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        FerretMessagesPluginApi.setUp(binding.binaryMessenger, null)
    }
}
